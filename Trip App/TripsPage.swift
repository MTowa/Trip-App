import SwiftUI

struct TripsPage: View {
    let repository: TripRepository
    let isHome: Bool
    let addTrip: () -> Void
    var showAllTrips: () -> Void = {}

    private var featuredTrip: TripSummary? {
        repository.trips.first { $0.endDate >= TripDates.today } ?? repository.trips.last
    }

    var body: some View {
        Group {
            if repository.trips.isEmpty {
                TripEmptyStateView(
                    title: "はじめての旅を計画しましょう",
                    message: "行き先と日程を決めて、旅のしおりを作成できます。",
                    systemImage: "suitcase",
                    actionTitle: "旅を追加",
                    action: addTrip
                )
            } else {
                ScrollView {
                    if isHome, let trip = featuredTrip {
                        HomeTripContent(
                            trip: trip,
                            pastTrips: repository.trips.filter { $0.endDate < TripDates.today }.reversed()
                        )
                        .padding(.horizontal, 25)
                        .padding(.vertical, 12)
                    } else {
                        LazyVStack(spacing: 40) {
                            ForEach(repository.trips.reversed()) { trip in
                                TripCardLink(trip: trip)
                            }
                        }
                        .padding(.horizontal, 25)
                        .padding(.vertical, 12)
                    }
                }
            }
        }
        .navigationTitle(isHome ? "最近の旅行" : "旅行一覧")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isHome {
                    Button("すべて見る", action: showAllTrips)
                } else {
                    Button("旅を追加", systemImage: "plus", action: addTrip)
                        .accessibilityIdentifier("add-trip-toolbar")
                }
            }
        }
        .modifier(TripPageStyle())
    }
}

private struct HomeTripContent: View {
    let trip: TripSummary
    let pastTrips: [TripSummary]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            TripCardLink(trip: trip)
            TripToolsView(trip: trip)
            VStack(alignment: .leading, spacing: 16) {
                TripHeading(title: "これまでの旅行")
                if pastTrips.isEmpty {
                    Text("旅行が終わると、ここに表示されます。")
                        .foregroundStyle(Color("TripSecondaryInk"))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color("TripPanel"), in: RoundedRectangle(cornerRadius: 19))
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12),
                                             count: dynamicTypeSize.isAccessibilitySize ? 1 : 2),
                              alignment: .leading, spacing: 16) {
                        ForEach(pastTrips) { trip in
                            TripCardLink(trip: trip, portrait: true)
                        }
                    }
                }
            }
        }
    }
}

struct TripCardLink: View {
    let trip: TripSummary
    var portrait = false

    var body: some View {
        NavigationLink {
            TripOverviewView(trip: trip)
        } label: {
            if portrait {
                PastTripCardView(destinationName: trip.destination, dateText: trip.dateText,
                                 coverAssetName: TripPresentation.cover(for: trip))
            } else {
                TripSummaryCard(trip: trip)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("trip-card")
        .accessibilityLabel("\(trip.destination)、\(trip.dateText)")
        .accessibilityHint("旅行の概要を開きます")
    }
}

struct TripSummaryCard: View {
    let trip: TripSummary

    var body: some View {
        TripCardView(destinationName: trip.destination, dateText: trip.dateText,
                     coverAssetName: TripPresentation.cover(for: trip),
                     startDateText: TripPresentation.compactDate(trip.startDate),
                     endDateText: TripPresentation.compactDate(trip.endDate))
    }
}

struct TripToolsView: View {
    let trip: TripSummary
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedSection: TripSection?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TripHeading(title: "\(trip.destination)旅行の情報")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8),
                                     count: dynamicTypeSize.isAccessibilitySize ? 1 : 3), spacing: 8) {
                ForEach(TripSection.allCases) { section in
                    TripSectionButton(section: section) { selectedSection = section }
                }
            }
        }
        .sheet(item: $selectedSection) { section in
            NavigationStack {
                ContentUnavailableView {
                    Label(section.title, systemImage: section.symbol)
                } description: {
                    Text("\(trip.destination)の情報を追加・編集する機能は準備中です。")
                }
                .navigationTitle(section.title)
                .navigationBarTitleDisplayMode(.inline)
                .modifier(TripPageStyle())
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("閉じる") { selectedSection = nil }
                    }
                }
            }
        }
    }
}

struct TripOverviewView: View {
    let trip: TripSummary

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                TripSummaryCard(trip: trip)
                TripToolsView(trip: trip)
                Label("この端末に保存済み", systemImage: "checkmark.circle")
                    .font(.subheadline)
            }
            .padding(.horizontal, 25)
            .padding(.vertical)
        }
        .navigationTitle("旅行の概要")
        .navigationBarTitleDisplayMode(.inline)
        .modifier(TripPageStyle())
        .accessibilityIdentifier("trip-overview")
    }
}
