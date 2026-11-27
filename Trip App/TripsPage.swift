import SwiftUI

struct TripsPage: View {
    let repository: TripRepository
    let isHome: Bool
    let addTrip: () -> Void

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
                    VStack(alignment: .leading, spacing: 24) {
                        if isHome {
                            Text("\(repository.displayName)さん、次はどこへ？")
                                .font(.title2.bold())
                        }
                        TripListSection(
                            title: "これからの旅行",
                            trips: repository.trips.filter { $0.endDate >= TripDates.today }
                        )
                        TripListSection(
                            title: "過去の旅行",
                            trips: repository.trips.filter { $0.endDate < TripDates.today }
                        )
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationTitle(isHome ? "ホーム" : "旅行一覧")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("旅を追加", systemImage: "plus", action: addTrip)
                    .accessibilityIdentifier("add-trip-toolbar")
            }
        }
    }
}

private struct TripListSection: View {
    let title: LocalizedStringKey
    let trips: [TripSummary]

    var body: some View {
        if !trips.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(title).font(.headline).accessibilityAddTraits(.isHeader)
                ForEach(trips) { trip in
                    NavigationLink {
                        TripOverviewView(trip: trip)
                    } label: {
                        TripCardView(
                            destinationName: trip.destination,
                            dateText: trip.dateText,
                            coverAssetName: nil,
                            companionNames: []
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("trip-card")
                    .accessibilityLabel("\(trip.destination)、\(trip.dateText)")
                    .accessibilityHint("旅行の概要を開きます")
                }
            }
        }
    }
}

struct TripOverviewView: View {
    let trip: TripSummary

    var body: some View {
        List {
            Section {
                TripCardView(
                    destinationName: trip.destination,
                    dateText: trip.dateText,
                    coverAssetName: nil,
                    companionNames: []
                )
                .listRowInsets(EdgeInsets())
            }
            Section("旅行について") {
                LabeledContent("行き先", value: trip.destination)
                Text(trip.dateText)
                Label("この端末に保存済み", systemImage: "checkmark.circle")
            }
            Section {
                Text("旅程・スポット・予約情報の追加機能は準備中です。")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("旅行の概要")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("trip-overview")
    }
}

struct AddTripView: View {
    let repository: TripRepository
    @State private var destination = ""
    @State private var startDate = TripDates.today
    @State private var endDate = TripDates.today
    @State private var createdTrip: TripSummary?
    @State private var errorMessage: String?
    @FocusState private var destinationFocused: Bool

    var body: some View {
        Form {
            Section {
                TextField("都市名", text: $destination)
                    .focused($destinationFocused)
                    .submitLabel(.done)
                    .onSubmit { destinationFocused = false }
                    .accessibilityIdentifier("destination-field")
                DatePicker("開始日", selection: $startDate, displayedComponents: .date)
                DatePicker("終了日", selection: $endDate, in: startDate..., displayedComponents: .date)
            } header: {
                Text("行き先と日程")
            } footer: {
                Text("都市名を入力してください。都市の写真が未登録の場合は共通の表紙で表示します。")
            }
            Section {
                Button("旅行を作成", action: save)
                    .disabled(destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("create-trip")
            } footer: {
                Text("作成した旅行は、この端末のホームと旅行一覧に表示されます。")
            }
        }
        .environment(\.timeZone, TripDates.timeZone)
        .navigationTitle("旅を追加")
        .onChange(of: startDate) { _, newValue in
            if endDate < newValue { endDate = newValue }
        }
        .sheet(item: $createdTrip) { trip in
            NavigationStack {
                TripOverviewView(trip: trip)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("完了") { createdTrip = nil }
                        }
                    }
            }
        }
        .alert("保存できませんでした", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func save() {
        do {
            destinationFocused = false
            createdTrip = try repository.addTrip(destination: destination, startDate: startDate, endDate: endDate)
            destination = ""
            startDate = TripDates.today
            endDate = TripDates.today
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
