import SwiftUI

enum TripTab: String, CaseIterable, Identifiable {
    case home, trips, addTrip, profile, settings

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .home: "ホーム"
        case .trips: "旅行一覧"
        case .addTrip: "旅を追加"
        case .profile: "プロフィール"
        case .settings: "設定"
        }
    }

    var symbol: String {
        switch self {
        case .home: "house"
        case .trips: "rectangle.stack"
        case .addTrip: "plus.app"
        case .profile: "person"
        case .settings: "gearshape"
        }
    }
}

/// Uses the iOS 17-compatible TabView API. Each tab retains its own navigation.
struct TripTabContainer<Content: View>: View {
    @Binding var selection: TripTab
    @ViewBuilder let content: (TripTab) -> Content

    var body: some View {
        TabView(selection: $selection) {
            ForEach(TripTab.allCases) { tab in
                NavigationStack {
                    content(tab)
                }
                .tabItem { Label(tab.title, systemImage: tab.symbol) }
                .tag(tab)
            }
        }
    }
}

enum TripSection: String, CaseIterable, Identifiable {
    case itinerary, places, bookings

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .itinerary: "旅程"
        case .places: "スポット"
        case .bookings: "予約情報"
        }
    }

    var symbol: String {
        switch self {
        case .itinerary: "calendar"
        case .places: "mappin.and.ellipse"
        case .bookings: "ticket"
        }
    }
}

struct TripSectionButton: View {
    let section: TripSection
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: section.symbol)
                    .font(.title2)
                Text(section.title)
                    .font(.subheadline.bold())
                    .multilineTextAlignment(.center)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 76)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 19))
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.accentColor)
        .accessibilityLabel(section.title)
        .accessibilityHint("旅行の情報を開きます")
    }
}

struct TripEmptyStateView: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let systemImage: String
    let actionTitle: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            Button(actionTitle, action: action)
                .buttonStyle(.borderedProminent)
                .foregroundStyle(Color(.systemBackground))
                .controlSize(.large)
                .accessibilityIdentifier("empty-state-action")
        }
    }
}
