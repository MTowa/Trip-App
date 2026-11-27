import Foundation
import SwiftData
import Testing
@testable import Trip_App

@MainActor
struct TripRepositoryTests {
    @Test func localTodayUsesCalendarDayInSelectedTimeZone() throws {
        let instant = Date(timeIntervalSince1970: 0)
        let tokyo = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let losAngeles = try #require(TimeZone(identifier: "America/Los_Angeles"))
        #expect(TripDates.localDay(containing: instant, timeZone: tokyo) == instant)
        #expect(TripDates.localDay(containing: instant, timeZone: losAngeles) == instant.addingTimeInterval(-86400))
    }

    @Test func tripAndProfileSurviveReopeningStore() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let configuration = ModelConfiguration(url: folder.appendingPathComponent("trips.store"), cloudKitDatabase: .none)
        let id: UUID
        do {
            let container = try ModelContainer(for: SavedTrip.self, LocalProfile.self, configurations: configuration)
            let repository = try TripRepository(container: container)
            #expect(repository.trips.isEmpty)
            id = try repository.addTrip(destination: " 京都 ", startDate: TripDates.today, endDate: TripDates.today).id
            try repository.updateProfile(name: " たびびと ")
        }
        let reopened = try ModelContainer(for: SavedTrip.self, LocalProfile.self, configurations: configuration)
        let repository = try TripRepository(container: reopened)
        #expect(repository.trips.count == 1)
        #expect(repository.trips.first?.id == id)
        #expect(repository.trips.first?.destination == "京都")
        #expect(repository.displayName == "たびびと")
        let profiles = try reopened.mainContext.fetch(FetchDescriptor<LocalProfile>())
        let trips = try reopened.mainContext.fetch(FetchDescriptor<SavedTrip>())
        #expect(profiles.count == 1)
        #expect(trips.first?.ownerID == profiles.first?.id)
    }

    @Test func invalidInputDoesNotCreateData() throws {
        let repository = try TripRepository(container: TripRepository.container(inMemory: true))
        #expect(throws: TripInputError.self) {
            try repository.addTrip(destination: " \n ", startDate: TripDates.today, endDate: TripDates.today)
        }
        #expect(throws: TripInputError.self) {
            try repository.addTrip(destination: "京都", startDate: TripDates.today, endDate: TripDates.today.addingTimeInterval(-86400))
        }
        #expect(throws: TripInputError.self) {
            try repository.updateProfile(name: String(repeating: "あ", count: 41))
        }
        #expect(repository.trips.isEmpty)
        #expect(repository.displayName == "旅行者")
    }

    @Test func memoryStoresAreIsolatedAndTripsSorted() throws {
        let repository = try TripRepository(container: TripRepository.container(inMemory: true))
        let today = TripDates.today
        let later = today.addingTimeInterval(86400 * 2)
        try repository.addTrip(destination: "東京", startDate: later, endDate: later)
        try repository.addTrip(destination: "京都", startDate: today, endDate: today)
        #expect(repository.trips.map(\.destination) == ["京都", "東京"])
        let separate = try TripRepository(container: TripRepository.container(inMemory: true))
        #expect(separate.trips.isEmpty)
    }
}
