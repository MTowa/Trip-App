import Foundation
import Observation
import SwiftData

@Model
final class SavedTripDetail {
    @Attribute(.unique) var tripID: UUID
    var payload: Data

    init(tripID: UUID, payload: Data) {
        self.tripID = tripID
        self.payload = payload
    }
}

enum TripEntryKind: String, Codable, CaseIterable, Identifiable {
    case itinerary, spot, flight, hotel, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .itinerary: "予定"
        case .spot: "スポット"
        case .flight: "飛行機"
        case .hotel: "ホテル"
        case .other: "その他の予約"
        }
    }
}

struct TripMember: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
}

struct TripEntry: Codable, Identifiable, Equatable {
    var id = UUID()
    var kind: TripEntryKind = .itinerary
    var title = ""
    var address = ""
    var category = ""
    var reservationNumber = ""
    var latitude: Double?
    var longitude: Double?
    var startDate = Date.now
    var endDate = Date.now.addingTimeInterval(3600)
    var departureTimeZone = TimeZone.current.identifier
    var arrivalTimeZone = TimeZone.current.identifier
    var departureAirport = ""
    var arrivalAirport = ""
    var airline = ""
    var flightNumber = ""

    var mapURL: URL? {
        if #available(iOS 18.4, *) { return mapURL(unified: true) }
        return mapURL(unified: false)
    }

    func mapURL(unified: Bool) -> URL? {
        var components = URLComponents(string: "https://maps.apple.com/")
        if let latitude, let longitude, (-90...90).contains(latitude), (-180...180).contains(longitude) {
            components?.path = unified ? "/place" : "/"
            components?.queryItems = [URLQueryItem(name: unified ? "coordinate" : "ll", value: "\(latitude),\(longitude)"),
                                      URLQueryItem(name: unified ? "name" : "q", value: title)]
        } else if !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            components?.path = unified ? "/search" : "/"
            components?.queryItems = [URLQueryItem(name: unified ? "query" : "q", value: address)]
        } else {
            return nil
        }
        return components?.url
    }

    func dateText(arrival: Bool = false) -> String {
        let identifier = arrival ? arrivalTimeZone : departureTimeZone
        let date = arrival ? endDate : startDate
        let zone = TimeZone(identifier: identifier) ?? .gmt
        let style = Date.FormatStyle(date: .abbreviated, time: kind == .hotel ? .omitted : .shortened,
                                     locale: Locale(identifier: "ja_JP"), timeZone: zone)
        return kind == .hotel ? date.formatted(style) : "\(date.formatted(style))（\(identifier)）"
    }
}

struct SeatAssignment: Codable, Equatable {
    var bookingID: UUID
    var memberID: UUID
    var seat: String
}

struct TripDocument: Codable, Equatable {
    var members: [TripMember] = []
    var entries: [TripEntry] = []
    var seats: [SeatAssignment] = []
}

enum TripDetailError: LocalizedError {
    case denied, missing, invalid(String)
    var errorDescription: String? {
        switch self {
        case .denied: "この操作を行う権限がありません。"
        case .missing: "旅行または予約が見つかりません。"
        case .invalid(let message): message
        }
    }
}

/// Local authorization boundary. Server authorization must be added before sharing is enabled.
@MainActor
@Observable
final class TripDetailStore {
    private let context: ModelContext
    private var documents: [UUID: TripDocument]
    private(set) var currentUserID: UUID

    init(container: ModelContainer, userID: UUID) throws {
        context = ModelContext(container)
        context.autosaveEnabled = false
        currentUserID = userID
        documents = [:]
        for record in try context.fetch(FetchDescriptor<SavedTripDetail>()) {
            documents[record.tripID] = try JSONDecoder().decode(TripDocument.self, from: record.payload)
        }
    }

    func isOwner(of tripID: UUID) -> Bool {
        (try? owner(of: tripID)) == currentUserID
    }

    func document(for tripID: UUID) throws -> TripDocument {
        let ownerID = try owner(of: tripID)
        let document = documents[tripID] ?? TripDocument(members: [TripMember(id: ownerID, name: "作成者")])
        guard ownerID == currentUserID || document.members.contains(where: { $0.id == currentUserID }) else {
            throw TripDetailError.denied
        }
        return document
    }

    func save(_ entry: TripEntry, tripID: UUID) throws {
        guard isOwner(of: tripID) else { throw TripDetailError.denied }
        var document = try document(for: tripID)
        var entry = entry
        entry.title = entry.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !entry.title.isEmpty, entry.title.count <= 100 else {
            throw TripDetailError.invalid("名前を1〜100文字で入力してください。")
        }
        guard entry.category.count <= 100, entry.reservationNumber.count <= 100 else {
            throw TripDetailError.invalid("カテゴリ・予約番号は100文字以内で入力してください。")
        }
        if entry.kind == .hotel {
            entry.startDate = TripDates.calendar.startOfDay(for: entry.startDate)
            entry.endDate = TripDates.calendar.startOfDay(for: entry.endDate)
            entry.departureTimeZone = "UTC"
            entry.arrivalTimeZone = "UTC"
        }
        guard entry.address.count <= 500 else { throw TripDetailError.invalid("住所は500文字以内で入力してください。") }
        if entry.latitude != nil || entry.longitude != nil {
            guard let lat = entry.latitude, let lon = entry.longitude,
                  lat.isFinite, lon.isFinite, (-90...90).contains(lat), (-180...180).contains(lon) else {
                throw TripDetailError.invalid("緯度は−90〜90、経度は−180〜180の両方を入力してください。")
            }
        }
        if entry.kind != .spot {
            guard TimeZone(identifier: entry.departureTimeZone) != nil,
                  TimeZone(identifier: entry.arrivalTimeZone) != nil,
                  entry.endDate >= entry.startDate else {
                throw TripDetailError.invalid("タイムゾーンと開始・終了の順序を確認してください。")
            }
        }
        if entry.kind == .flight {
            let required = [entry.departureAirport, entry.arrivalAirport, entry.airline, entry.flightNumber]
            guard required.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.count <= 100 }) else {
                throw TripDetailError.invalid("出発・到着空港、航空会社、便名を1〜100文字で入力してください。")
            }
        }
        if let index = document.entries.firstIndex(where: { $0.id == entry.id }) {
            guard document.entries[index].kind == entry.kind else {
                throw TripDetailError.invalid("保存済みの項目の種類は変更できません。")
            }
            document.entries[index] = entry
        } else {
            document.entries.append(entry)
        }
        try persist(document, tripID: tripID)
    }

    func saveSeat(_ seat: String, bookingID: UUID, memberID: UUID, tripID: UUID) throws {
        var document = try document(for: tripID)
        guard isOwner(of: tripID) || memberID == currentUserID else { throw TripDetailError.denied }
        guard document.members.contains(where: { $0.id == memberID }),
              document.entries.contains(where: { $0.id == bookingID && $0.kind == .flight }) else {
            throw TripDetailError.missing
        }
        let value = seat.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.count <= 20 else { throw TripDetailError.invalid("座席は20文字以内で入力してください。") }
        document.seats.removeAll { $0.bookingID == bookingID && $0.memberID == memberID }
        if !value.isEmpty {
            document.seats.append(SeatAssignment(bookingID: bookingID, memberID: memberID, seat: value))
        }
        try persist(document, tripID: tripID)
    }

    private func owner(of tripID: UUID) throws -> UUID {
        let trips = try context.fetch(FetchDescriptor<SavedTrip>())
        guard let trip = trips.first(where: { $0.id == tripID }) else { throw TripDetailError.missing }
        return trip.ownerID
    }

    private func persist(_ document: TripDocument, tripID: UUID) throws {
        let data = try JSONEncoder().encode(document)
        if let record = try context.fetch(FetchDescriptor<SavedTripDetail>()).first(where: { $0.tripID == tripID }) {
            record.payload = data
        } else {
            context.insert(SavedTripDetail(tripID: tripID, payload: data))
        }
        do {
            try context.save()
            documents[tripID] = document
        } catch {
            context.rollback()
            throw error
        }
    }

    #if DEBUG
    static let previewParticipantID = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA") ?? UUID()

    func preparePreview(tripID: UUID, asParticipant: Bool) throws {
        guard isOwner(of: tripID) else { throw TripDetailError.denied }
        var document = try document(for: tripID)
        document.members.append(TripMember(id: Self.previewParticipantID, name: "参加者サンプル"))
        try persist(document, tripID: tripID)
        if asParticipant { currentUserID = Self.previewParticipantID }
    }
    #endif
}
