import Foundation
import SwiftData
import Testing
@testable import Trip_App

@MainActor
struct TripDetailTests {
    private func flight() -> TripEntry {
        var entry = TripEntry()
        entry.kind = .flight
        entry.title = "東京→パリ"
        entry.departureAirport = "HND"
        entry.arrivalAirport = "CDG"
        entry.airline = "サンプル航空"
        entry.flightNumber = "TEST1"
        entry.departureTimeZone = "Asia/Tokyo"
        entry.arrivalTimeZone = "Europe/Paris"
        entry.startDate = Date(timeIntervalSince1970: 0)
        entry.endDate = Date(timeIntervalSince1970: 3600 * 14)
        return entry
    }

    @Test func ownerAndParticipantPermissionsAreEnforcedAtSave() throws {
        let container = try TripRepository.container(inMemory: true)
        let repository = try TripRepository(container: container)
        let trip = try repository.addTrip(destination: "パリ", startDate: TripDates.today, endDate: TripDates.today)
        let owner = repository.details
        let entry = flight()
        try owner.save(entry, tripID: trip.id)
        try owner.preparePreview(tripID: trip.id, asParticipant: false)
        let ownerID = owner.currentUserID
        let memberID = TripDetailStore.previewParticipantID
        try owner.saveSeat("1A", bookingID: entry.id, memberID: ownerID, tripID: trip.id)
        try owner.saveSeat("2A", bookingID: entry.id, memberID: memberID, tripID: trip.id)

        let participant = try TripDetailStore(container: container, userID: memberID)
        #expect(try participant.document(for: trip.id).entries.count == 1)
        try participant.saveSeat("12B", bookingID: entry.id, memberID: memberID, tripID: trip.id)
        #expect(throws: TripDetailError.self) { try participant.save(entry, tripID: trip.id) }
        #expect(throws: TripDetailError.self) {
            try participant.saveSeat("99A", bookingID: entry.id, memberID: ownerID, tripID: trip.id)
        }
        let document = try participant.document(for: trip.id)
        #expect(document.seats.first { $0.memberID == ownerID }?.seat == "1A")
        #expect(document.seats.first { $0.memberID == memberID }?.seat == "12B")
        #expect(document.entries.first == entry)
        try participant.saveSeat("", bookingID: entry.id, memberID: memberID, tripID: trip.id)
        #expect(try participant.document(for: trip.id).seats.count == 1)

        let outsider = try TripDetailStore(container: container, userID: UUID())
        #expect(throws: TripDetailError.self) { try outsider.document(for: trip.id) }
        #expect(throws: TripDetailError.self) { try outsider.save(entry, tripID: trip.id) }
        #expect(throws: TripDetailError.self) {
            try outsider.saveSeat("1B", bookingID: entry.id, memberID: memberID, tripID: trip.id)
        }
    }

    @Test func invalidDetailsDoNotMutateSavedDocument() throws {
        let repository = try TripRepository(container: TripRepository.container(inMemory: true))
        let trip = try repository.addTrip(destination: "東京", startDate: TripDates.today, endDate: TripDates.today)
        let store = repository.details
        var entry = flight()
        try store.save(entry, tripID: trip.id)
        entry.endDate = entry.startDate.addingTimeInterval(-1)
        #expect(throws: TripDetailError.self) { try store.save(entry, tripID: trip.id) }
        entry = flight()
        entry.flightNumber = " "
        #expect(throws: TripDetailError.self) { try store.save(entry, tripID: trip.id) }
        entry = flight()
        entry.departureTimeZone = "invalid/timezone"
        #expect(throws: TripDetailError.self) { try store.save(entry, tripID: trip.id) }
        var spot = TripEntry()
        spot.kind = .spot
        spot.title = "京都駅"
        spot.latitude = 200
        spot.longitude = 0
        #expect(throws: TripDetailError.self) { try store.save(spot, tripID: trip.id) }
        #expect(try store.document(for: trip.id).entries.count == 1)
    }

    @Test func legacyTripsMigrateAndDetailsSurviveReopening() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let configuration = ModelConfiguration(url: directory.appendingPathComponent("trips.store"), cloudKitDatabase: .none)
        let tripID = UUID()
        let userID = UUID()
        do {
            let legacy = try ModelContainer(for: SavedTrip.self, LocalProfile.self, configurations: configuration)
            let context = ModelContext(legacy)
            context.insert(LocalProfile(id: userID, displayName: "保存テスト"))
            context.insert(SavedTrip(id: tripID, ownerID: userID, destination: "パリ", startDate: TripDates.today, endDate: TripDates.today))
            try context.save()
        }
        let booking = flight()
        do {
            let upgraded = try ModelContainer(for: SavedTrip.self, LocalProfile.self, SavedTripDetail.self, configurations: configuration)
            let repository = try TripRepository(container: upgraded)
            #expect(repository.trips.first?.id == tripID)
            #expect(repository.displayName == "保存テスト")
            try repository.details.save(booking, tripID: tripID)
            try repository.details.saveSeat("18C", bookingID: booking.id, memberID: userID, tripID: tripID)
            var edited = booking
            edited.flightNumber = "TEST2"
            try repository.details.save(edited, tripID: tripID)
            try repository.updateTrip(id: tripID, destination: "パリ改", startDate: TripDates.today, endDate: TripDates.today)
        }
        let reopened = try ModelContainer(for: SavedTrip.self, LocalProfile.self, SavedTripDetail.self, configurations: configuration)
        let repository = try TripRepository(container: reopened)
        let document = try repository.details.document(for: tripID)
        #expect(document.entries.count == 1)
        #expect(document.entries.first?.flightNumber == "TEST2")
        #expect(document.seats.first?.seat == "18C")
        #expect(repository.trips.first?.destination == "パリ改")
    }

    @Test func itineraryAndHotelEditsKeepStableIDsAndCalendarDays() throws {
        let repository = try TripRepository(container: TripRepository.container(inMemory: true))
        let trip = try repository.addTrip(destination: "京都", startDate: TripDates.today, endDate: TripDates.today)
        var plan = TripEntry()
        plan.title = "集合"
        try repository.details.save(plan, tripID: trip.id)
        plan.title = "駅前集合"
        try repository.details.save(plan, tripID: trip.id)
        var hotel = TripEntry()
        hotel.kind = .hotel
        hotel.title = "ホテル"
        hotel.startDate = TripDates.today.addingTimeInterval(3600 * 12)
        hotel.endDate = TripDates.today.addingTimeInterval(86400 * 2 + 3600 * 10)
        try repository.details.save(hotel, tripID: trip.id)
        let document = try repository.details.document(for: trip.id)
        #expect(document.entries.count == 2)
        #expect(document.entries.first { $0.id == plan.id }?.title == "駅前集合")
        let savedHotel = try #require(document.entries.first { $0.id == hotel.id })
        #expect(savedHotel.startDate == TripDates.today)
        #expect(savedHotel.endDate == TripDates.today.addingTimeInterval(86400 * 2))
        #expect(savedHotel.departureTimeZone == "UTC")
        #expect(throws: TripDetailError.self) {
            try repository.details.saveSeat("1A", bookingID: hotel.id, memberID: repository.details.currentUserID, tripID: trip.id)
        }
        try repository.details.preparePreview(tripID: trip.id, asParticipant: true)
        #expect(throws: TripDetailError.self) {
            try repository.updateTrip(id: trip.id, destination: "変更不可", startDate: TripDates.today, endDate: TripDates.today)
        }
        #expect(repository.trips.first?.destination == "京都")
    }

    @Test func mapsURLsEncodeAddressesAndPreferCoordinates() throws {
        var spot = TripEntry()
        spot.kind = .spot
        spot.title = "駅 & 公園"
        #expect(spot.mapURL == nil)
        spot.address = "京都駅 & 東口 #1"
        let addressURL = try #require(spot.mapURL)
        #expect(URLComponents(url: addressURL, resolvingAgainstBaseURL: false)?.queryItems?.first?.value == spot.address)
        spot.latitude = 35.0
        spot.longitude = 135.0
        let coordinateURL = try #require(spot.mapURL(unified: false))
        let query = try #require(URLComponents(url: coordinateURL, resolvingAgainstBaseURL: false)?.queryItems)
        #expect(query.contains(URLQueryItem(name: "ll", value: "35.0,135.0")))
        #expect(query.contains(URLQueryItem(name: "q", value: spot.title)))
        let modernURL = try #require(spot.mapURL(unified: true))
        let modern = try #require(URLComponents(url: modernURL, resolvingAgainstBaseURL: false))
        #expect(modern.path == "/place")
        #expect(modern.queryItems?.contains(URLQueryItem(name: "coordinate", value: "35.0,135.0")) == true)
    }

    @Test func flightDisplaysBothLocalTimesAcrossDateLine() {
        var entry = flight()
        entry.startDate = Date(timeIntervalSince1970: 0)
        entry.endDate = Date(timeIntervalSince1970: 3600)
        entry.arrivalTimeZone = "America/Los_Angeles"
        #expect(entry.dateText().contains("1970"))
        #expect(entry.dateText().contains("Asia/Tokyo"))
        #expect(entry.dateText(arrival: true).contains("1969"))
        #expect(entry.dateText(arrival: true).contains("America/Los_Angeles"))
    }
}
