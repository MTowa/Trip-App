import SwiftUI

struct ContentView: View {
    @State private var repository: TripRepository?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let repository {
                MainTabsView(repository: repository)
                    .environment(repository.details)
                    .environment(repository)
            } else if loadFailed {
                TripEmptyStateView(
                    title: "データを開けませんでした",
                    message: "端末の空き容量を確認して、もう一度お試しください。",
                    systemImage: "exclamationmark.triangle",
                    actionTitle: "再試行",
                    action: load
                )
            } else {
                ProgressView("旅行を読み込み中")
            }
        }
        .task { if repository == nil { load() } }
    }

    private func load() {
        loadFailed = false
        do {
            var inMemory = false
            #if DEBUG
            inMemory = ProcessInfo.processInfo.arguments.contains("--ui-testing")
                || ProcessInfo.processInfo.arguments.contains("--design-preview")
                || ProcessInfo.processInfo.arguments.contains("--details-preview")
                || ProcessInfo.processInfo.arguments.contains("--participant-preview")
            #endif
            let loaded = try TripRepository(container: TripRepository.container(inMemory: inMemory))
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--design-preview") {
                for (city, start, end) in [("京都", -20, -17), ("パリ", -10, -7), ("パリ", 2, 5)] {
                    guard let startDate = TripDates.calendar.date(byAdding: .day, value: start, to: TripDates.today),
                          let endDate = TripDates.calendar.date(byAdding: .day, value: end, to: TripDates.today) else { continue }
                    try loaded.addTrip(destination: city, startDate: startDate, endDate: endDate)
                }
            }
            if ProcessInfo.processInfo.arguments.contains("--details-preview")
                || ProcessInfo.processInfo.arguments.contains("--participant-preview") {
                let trip = try loaded.addTrip(destination: "パリ（検証用）", startDate: TripDates.today, endDate: TripDates.today.addingTimeInterval(86400 * 4))
                var flight = TripEntry()
                flight.kind = .flight
                flight.title = "パリへのフライト（サンプル）"
                flight.departureAirport = "羽田 HND"
                flight.arrivalAirport = "パリ CDG"
                flight.airline = "サンプル航空"
                flight.flightNumber = "DEMO001"
                flight.departureTimeZone = "Asia/Tokyo"
                flight.arrivalTimeZone = "Europe/Paris"
                flight.startDate = TripDates.today
                flight.endDate = TripDates.today.addingTimeInterval(14 * 3600)
                try loaded.details.save(flight, tripID: trip.id)
                try loaded.details.preparePreview(tripID: trip.id, asParticipant: ProcessInfo.processInfo.arguments.contains("--participant-preview"))
            }
            #endif
            repository = loaded
        } catch {
            loadFailed = true
        }
    }
}

struct MainTabsView: View {
    let repository: TripRepository
    @State private var selection: TripTab = .home

    var body: some View {
        TripTabContainer(selection: $selection) { tab in
            switch tab {
            case .home:
                TripsPage(repository: repository, isHome: true, addTrip: { selection = .addTrip },
                          showAllTrips: { selection = .trips })
            case .trips:
                TripsPage(repository: repository, isHome: false, addTrip: { selection = .addTrip })
            case .addTrip:
                AddTripView(repository: repository)
            case .profile:
                ProfilePage(repository: repository)
            case .settings:
                SettingsPage()
            }
        }
    }
}
