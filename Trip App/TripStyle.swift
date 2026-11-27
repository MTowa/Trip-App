import SwiftUI

struct TripPageStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .fontDesign(.rounded)
            .foregroundStyle(Color("TripInk"))
            .scrollContentBackground(.hidden)
            .background {
                LinearGradient(colors: [Color("TripBackgroundStart"), Color("TripBackgroundEnd")],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            }
            .toolbarBackground(.hidden, for: .navigationBar)
    }
}

struct TripHeading: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .font(.title2.bold())
            .foregroundStyle(Color("TripInk"))
            .accessibilityAddTraits(.isHeader)
    }
}

struct TripIconTile: View {
    let symbol: String

    var body: some View {
        Image(systemName: symbol)
            .font(.title3)
            .foregroundStyle(Color.accentColor)
            .frame(width: 43, height: 43)
            .background(Color("TripIconTile"), in: RoundedRectangle(cornerRadius: 13))
            .accessibilityHidden(true)
    }
}

struct TripInfoRow: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let symbol: String

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            TripIconTile(symbol: symbol)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.headline)
                Text(message).font(.subheadline).foregroundStyle(Color("TripSecondaryInk"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}

enum TripPresentation {
    static func cover(for trip: TripSummary) -> String? {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--design-preview") {
            switch trip.destination {
            case "パリ": return "DemoCoverParis"
            case "京都": return "DemoCoverKyoto"
            default: return nil
            }
        }
        #endif
        return nil
    }

    static func compactDate(_ date: Date) -> String {
        let components = TripDates.calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d.%02d.%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }
}
