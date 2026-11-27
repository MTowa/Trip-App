import SwiftUI

struct ContentView: View {
    @State private var repository: TripRepository?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let repository {
                MainTabsView(repository: repository)
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
            #endif
            repository = try TripRepository(container: TripRepository.container(inMemory: inMemory))
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
                TripsPage(repository: repository, isHome: true) { selection = .addTrip }
            case .trips:
                TripsPage(repository: repository, isHome: false) { selection = .addTrip }
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
