import SwiftUI

struct AddTripView: View {
    let repository: TripRepository
    @State private var destination = ""
    @State private var startDate = TripDates.today
    @State private var endDate = TripDates.today
    @State private var createdTrip: TripSummary?
    @State private var errorMessage: String?
    @FocusState private var destinationFocused: Bool
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Form {
            Section("行き先") {
                HStack {
                    Image(systemName: "magnifyingglass").accessibilityHidden(true)
                    TextField("都市名", text: $destination)
                        .focused($destinationFocused)
                        .submitLabel(.done)
                        .onSubmit { destinationFocused = false }
                        .accessibilityIdentifier("destination-field")
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color("TripPanel"))

            Section {
                let layout = typeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
                    : AnyLayout(HStackLayout(spacing: 12))
                layout {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(destination.isEmpty ? "旅行カードの表紙" : destination)
                            .font(.title3.bold())
                        Text("都市の写真が未登録のため、共通の表紙で表示します。")
                            .font(.subheadline)
                            .foregroundStyle(Color("TripSecondaryInk"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image("DestinationPlaceholder")
                        .resizable().scaledToFit()
                        .frame(width: 112, height: 112)
                        .accessibilityHidden(true)
                }
                .padding(18)
                .frame(maxWidth: .infinity, minHeight: 188)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color("TripPreviewSurface"))

            Section("出発前の準備") {
                NavigationLink {
                    Form {
                        DatePicker("開始日", selection: $startDate, displayedComponents: .date)
                        DatePicker("終了日", selection: $endDate, in: startDate..., displayedComponents: .date)
                    }
                    .navigationTitle("旅行日程")
                    .modifier(TripPageStyle())
                } label: {
                    TripInfoRow(title: "旅行日程",
                                message: "\(TripPresentation.compactDate(startDate)) 〜 \(TripPresentation.compactDate(endDate))",
                                symbol: "calendar")
                }
                .accessibilityIdentifier("trip-dates")
                NavigationLink {
                    FriendAvailabilityView()
                } label: {
                    TripInfoRow(title: "同行者を招待", message: "準備中・アカウント登録機能の公開後に利用できます", symbol: "person.badge.plus")
                }
            }
            .listRowBackground(Color("TripPanel"))

            Section {
                Button(action: save) {
                    Text("旅行カードを作成")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .foregroundStyle(Color(.systemBackground))
                .disabled(destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("create-trip")
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } footer: {
                Text("作成した旅行は、この端末のホームと旅行一覧に表示されます。")
            }
        }
        .modifier(TripPageStyle())
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
