import SwiftUI

struct TripHeaderEditor: View {
    let repository: TripRepository
    let trip: TripSummary
    @State private var destination: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    init(repository: TripRepository, trip: TripSummary) {
        self.repository = repository
        self.trip = trip
        _destination = State(initialValue: trip.destination)
        _startDate = State(initialValue: trip.startDate)
        _endDate = State(initialValue: trip.endDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("都市名", text: $destination)
                    DatePicker("開始日", selection: $startDate, displayedComponents: .date)
                    DatePicker("終了日", selection: $endDate, in: startDate..., displayedComponents: .date)
                } footer: {
                    Text("旅行の日程を変更しても、登録済みの予定や予約の日時は変わりません。")
                }
                .listRowBackground(Color("TripPanel"))
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            }
            .environment(\.timeZone, TripDates.timeZone)
            .navigationTitle("旅行を編集")
            .modifier(TripPageStyle())
            .onChange(of: startDate) { _, value in
                if endDate < value { endDate = value }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        do {
                            try repository.updateTrip(id: trip.id, destination: destination, startDate: startDate, endDate: endDate)
                            dismiss()
                        } catch { errorMessage = error.localizedDescription }
                    }
                }
            }
        }
    }
}
