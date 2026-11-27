import Foundation
import Observation
import SwiftData

@Model
final class SavedTrip {
    @Attribute(.unique) var id: UUID
    var ownerID: UUID
    var destination: String
    var startDate: Date
    var endDate: Date

    init(id: UUID = UUID(), ownerID: UUID, destination: String, startDate: Date, endDate: Date) {
        self.id = id
        self.ownerID = ownerID
        self.destination = destination
        self.startDate = startDate
        self.endDate = endDate
    }
}

@Model
final class LocalProfile {
    @Attribute(.unique) var id: UUID
    var displayName: String

    init(id: UUID = UUID(), displayName: String = "旅行者") {
        self.id = id
        self.displayName = displayName
    }
}

struct TripSummary: Identifiable, Equatable {
    let id: UUID
    let destination: String
    let startDate: Date
    let endDate: Date

    var dateText: String {
        let style = Date.FormatStyle(date: .abbreviated, time: .omitted,
                                    locale: Locale(identifier: "ja_JP"),
                                    timeZone: TripDates.timeZone)
        return "\(startDate.formatted(style)) 〜 \(endDate.formatted(style))"
    }
}

enum TripDates {
    // Travel dates are calendar days, encoded at UTC midnight to avoid device timezone shifts.
    static let timeZone = TimeZone(identifier: "UTC") ?? .gmt
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
    static var today: Date {
        localDay(containing: .now, timeZone: .current)
    }

    static func localDay(containing date: Date, timeZone: TimeZone) -> Date {
        var localCalendar = Calendar(identifier: .gregorian)
        localCalendar.timeZone = timeZone
        let components = localCalendar.dateComponents([.year, .month, .day], from: date)
        return calendar.date(from: components) ?? calendar.startOfDay(for: date)
    }
}

enum TripInputError: LocalizedError {
    case emptyDestination, invalidDates, invalidName

    var errorDescription: String? {
        switch self {
        case .emptyDestination: "都市名を1〜100文字で入力してください。"
        case .invalidDates: "終了日は開始日以降にしてください。"
        case .invalidName: "表示名を1〜40文字で入力してください。"
        }
    }
}

@MainActor
@Observable
final class TripRepository {
    private let context: ModelContext
    private let profile: LocalProfile
    private(set) var trips: [TripSummary]
    private(set) var displayName: String

    init(container: ModelContainer) throws {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        self.context = context
        if let existing = try context.fetch(FetchDescriptor<LocalProfile>()).first {
            profile = existing
        } else {
            let newProfile = LocalProfile()
            context.insert(newProfile)
            try context.save()
            profile = newProfile
        }
        displayName = profile.displayName
        trips = try Self.fetchTrips(context)
    }

    static func container(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: inMemory, cloudKitDatabase: .none
        )
        return try ModelContainer(for: SavedTrip.self, LocalProfile.self, configurations: configuration)
    }

    @discardableResult
    func addTrip(destination: String, startDate: Date, endDate: Date) throws -> TripSummary {
        let name = destination.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.count <= 100 else { throw TripInputError.emptyDestination }
        let start = TripDates.calendar.startOfDay(for: startDate)
        let end = TripDates.calendar.startOfDay(for: endDate)
        guard end >= start else { throw TripInputError.invalidDates }
        let trip = SavedTrip(ownerID: profile.id, destination: name, startDate: start, endDate: end)
        context.insert(trip)
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        let summary = TripSummary(id: trip.id, destination: name, startDate: start, endDate: end)
        trips.append(summary)
        trips.sort { $0.startDate < $1.startDate }
        return summary
    }

    func updateProfile(name: String) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 40 else { throw TripInputError.invalidName }
        profile.displayName = trimmed
        do {
            try context.save()
            displayName = trimmed
        } catch {
            context.rollback()
            throw error
        }
    }

    private static func fetchTrips(_ context: ModelContext) throws -> [TripSummary] {
        try context.fetch(FetchDescriptor<SavedTrip>(sortBy: [SortDescriptor(\.startDate)]))
            .map { TripSummary(id: $0.id, destination: $0.destination, startDate: $0.startDate, endDate: $0.endDate) }
    }
}
