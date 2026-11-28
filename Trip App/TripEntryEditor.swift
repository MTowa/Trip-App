import SwiftUI

struct TripEntryEditor: View {
    let tripID: UUID
    let isNew: Bool
    @State private var entry: TripEntry
    @State private var latitude: String
    @State private var longitude: String
    @State private var errorMessage: String?
    @Environment(TripDetailStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    init(tripID: UUID, initial: TripEntry, isNew: Bool) {
        self.tripID = tripID
        self.isNew = isNew
        _entry = State(initialValue: initial)
        _latitude = State(initialValue: initial.latitude.map { String($0) } ?? "")
        _longitude = State(initialValue: initial.longitude.map { String($0) } ?? "")
    }

    var body: some View {
        Form {
            Section("詳細") {
                field("名前（必須）", text: $entry.title, identifier: "entry-title")
                if [.flight, .hotel, .other].contains(entry.kind) {
                    if isNew {
                        Picker("予約の種類", selection: $entry.kind) {
                            ForEach([TripEntryKind.flight, .hotel, .other]) { kind in
                                Text(kind.title).tag(kind)
                            }
                        }
                        .accessibilityIdentifier("booking-kind")
                    } else {
                        LabeledContent("予約の種類", value: entry.kind.title)
                    }
                    field("予約番号", text: $entry.reservationNumber)
                }
                if entry.kind == .spot {
                    field("カテゴリ", text: $entry.category)
                }
            }
            .listRowBackground(Color("TripPanel"))

            if entry.kind == .flight {
                Section("フライトの共通情報") {
                    field("出発空港", text: $entry.departureAirport, identifier: "departure-airport")
                    field("到着空港", text: $entry.arrivalAirport, identifier: "arrival-airport")
                    field("航空会社", text: $entry.airline, identifier: "airline")
                    field("便名", text: $entry.flightNumber, identifier: "flight-number")
                }
                .listRowBackground(Color("TripPanel"))
            } else {
                Section {
                    field("住所・最寄り駅", text: $entry.address, identifier: "entry-address")
                    if entry.kind == .spot || entry.kind == .hotel {
                        field("緯度（任意）", text: $latitude, identifier: "entry-latitude")
                        field("経度（任意）", text: $longitude, identifier: "entry-longitude")
                    }
                } header: {
                    Text(entry.kind == .itinerary ? "集合場所" : "場所")
                } footer: {
                    Text("住所または緯度・経度を登録するとApple Mapsで開けます。")
                }
                .listRowBackground(Color("TripPanel"))
            }

            if entry.kind != .spot {
                EntryDateFields(entry: $entry)
            }

            if let errorMessage {
                Section { Text(errorMessage).foregroundStyle(.red).accessibilityIdentifier("entry-error") }
                    .listRowBackground(Color("TripPanel"))
            }
            Section {
                Button(action: save) {
                    Text("カードに保存").font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .foregroundStyle(Color(.systemBackground))
                .accessibilityIdentifier("save-entry")
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
        }
        .navigationTitle("\(entry.kind.title)を\(isNew ? "追加" : "編集")")
        .navigationBarTitleDisplayMode(.inline)
        .modifier(TripPageStyle())
        .alert("保存できませんでした", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存", action: save).accessibilityIdentifier("save-entry-toolbar")
            }
        }
    }

    private func field(_ title: LocalizedStringKey, text: Binding<String>, identifier: String = "") -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption.bold()).foregroundStyle(Color("TripSecondaryInk"))
            TextField(title, text: text, axis: .vertical)
                .accessibilityIdentifier(identifier)
        }
        .padding(.vertical, 6)
    }

    private func save() {
        let lat = latitude.trimmingCharacters(in: .whitespacesAndNewlines)
        let lon = longitude.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (lat.isEmpty || Double(lat) != nil), (lon.isEmpty || Double(lon) != nil) else {
            errorMessage = "座標は半角数字と小数点、必要に応じてマイナス符号で入力してください。"
            return
        }
        entry.latitude = Double(lat)
        entry.longitude = Double(lon)
        if entry.kind == .hotel {
            entry.startDate = TripDates.calendar.startOfDay(for: entry.startDate)
            entry.endDate = TripDates.calendar.startOfDay(for: entry.endDate)
            entry.departureTimeZone = "UTC"
            entry.arrivalTimeZone = "UTC"
        } else if entry.kind != .flight {
            entry.arrivalTimeZone = entry.departureTimeZone
        }
        do {
            try store.save(entry, tripID: tripID)
            dismiss()
        } catch { errorMessage = error.localizedDescription }
    }
}

private struct EntryDateFields: View {
    @Binding var entry: TripEntry

    var body: some View {
        if entry.kind == .hotel {
            Section("宿泊日") {
                DatePicker("チェックイン", selection: $entry.startDate, displayedComponents: .date)
                DatePicker("チェックアウト", selection: $entry.endDate, in: entry.startDate..., displayedComponents: .date)
            }
            .environment(\.timeZone, TripDates.timeZone)
            .listRowBackground(Color("TripPanel"))
        } else {
            Section {
                NavigationLink {
                    TimeZonePicker(selection: $entry.departureTimeZone)
                } label: {
                    LabeledContent("タイムゾーン", value: entry.departureTimeZone)
                }
                DatePicker(entry.kind == .flight ? "出発日時" : "開始日時", selection: $entry.startDate)
                    .environment(\.timeZone, TimeZone(identifier: entry.departureTimeZone) ?? .gmt)
                if entry.kind != .flight {
                    DatePicker("終了日時", selection: $entry.endDate)
                        .environment(\.timeZone, TimeZone(identifier: entry.departureTimeZone) ?? .gmt)
                }
            } header: {
                Text(entry.kind == .flight ? "出発地の現地時刻" : "日程")
            } footer: {
                Text("タイムゾーンを変更すると、同じ瞬間をその地域の現地時刻で表示します。日時も確認してください。")
            }
            .listRowBackground(Color("TripPanel"))
            if entry.kind == .flight {
                Section("到着地の現地時刻") {
                    NavigationLink {
                        TimeZonePicker(selection: $entry.arrivalTimeZone)
                    } label: {
                        LabeledContent("タイムゾーン", value: entry.arrivalTimeZone)
                    }
                    DatePicker("到着日時", selection: $entry.endDate)
                        .environment(\.timeZone, TimeZone(identifier: entry.arrivalTimeZone) ?? .gmt)
                }
                .listRowBackground(Color("TripPanel"))
            }
        }
    }
}

private struct TimeZonePicker: View {
    @Binding var selection: String
    @State private var search = ""
    @Environment(\.dismiss) private var dismiss
    private let identifiers = TimeZone.knownTimeZoneIdentifiers

    var body: some View {
        List(identifiers.filter { search.isEmpty || $0.localizedCaseInsensitiveContains(search) }, id: \.self) { identifier in
            Button {
                selection = identifier
                dismiss()
            } label: {
                HStack {
                    Text(identifier)
                    Spacer()
                    if selection == identifier { Image(systemName: "checkmark") }
                }
            }
            .listRowBackground(Color("TripPanel"))
        }
        .searchable(text: $search, prompt: "Tokyo、Parisなどで検索")
        .navigationTitle("タイムゾーン")
        .modifier(TripPageStyle())
    }
}
