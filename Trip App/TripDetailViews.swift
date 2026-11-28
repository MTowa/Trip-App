import SwiftUI

struct TripDetailPage: View {
    let trip: TripSummary
    @State var section: TripSection
    @Environment(TripDetailStore.self) private var store
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var editingEntry: TripEntry?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(trip.destination).font(.headline).foregroundStyle(Color("TripSecondaryInk"))
                if typeSize.isAccessibilitySize {
                    sectionPicker.pickerStyle(.menu)
                } else {
                    sectionPicker.pickerStyle(.segmented)
                }
                if let document = try? store.document(for: trip.id) {
                    let entries = document.entries.filter(matches).sorted { $0.startDate < $1.startDate }
                    if !store.isOwner(of: trip.id) {
                        Label("参加者：自分の座席のみ編集できます", systemImage: "person")
                            .font(.subheadline)
                    }
                    if entries.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            TripInfoRow(title: "まだ登録されていません", message: "旅行の情報をここにまとめられます。", symbol: section.symbol)
                            if store.isOwner(of: trip.id) {
                                Button("最初の項目を追加", action: add)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color("TripPanel"), in: RoundedRectangle(cornerRadius: 19))
                    }
                    ForEach(entries) { entry in
                        NavigationLink {
                            TripEntryDetail(tripID: trip.id, entryID: entry.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                Label(entry.title, systemImage: section.symbol).font(.headline)
                                if entry.kind == .spot {
                                    Text(entry.address.isEmpty ? "場所を追加入力できます" : entry.address)
                                } else {
                                    Text(entry.dateText())
                                }
                                Text(entry.kind.title).font(.caption)
                            }
                            .foregroundStyle(Color("TripInk"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(18)
                            .background(Color("TripPanel"), in: RoundedRectangle(cornerRadius: 19))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("detail-entry")
                    }
                } else {
                    ContentUnavailableView("旅行を開けません", systemImage: "lock", description: Text("この旅行を閲覧する権限がありません。"))
                }
            }
            .padding(25)
        }
        .navigationTitle(section.title)
        .navigationBarTitleDisplayMode(.inline)
        .modifier(TripPageStyle())
        .toolbar {
            if store.isOwner(of: trip.id) {
                ToolbarItem(placement: .primaryAction) {
                    Button("追加", systemImage: "plus", action: add)
                        .accessibilityIdentifier("add-detail")
                }
            }
        }
        .sheet(item: $editingEntry) { entry in
            NavigationStack {
                TripEntryEditor(tripID: trip.id, initial: entry, isNew: true)
            }
        }
    }

    private var sectionPicker: some View {
        Picker("旅行の情報", selection: $section) {
            ForEach(TripSection.allCases) { section in
                Text(section.title).tag(section)
            }
        }
        .accessibilityIdentifier("detail-section-picker")
    }

    private func matches(_ entry: TripEntry) -> Bool {
        switch section {
        case .itinerary: entry.kind == .itinerary
        case .places: entry.kind == .spot
        case .bookings: [.flight, .hotel, .other].contains(entry.kind)
        }
    }

    private func add() {
        var entry = TripEntry()
        entry.kind = section == .itinerary ? .itinerary : section == .places ? .spot : .flight
        entry.startDate = trip.startDate
        entry.endDate = trip.startDate.addingTimeInterval(3600)
        editingEntry = entry
    }
}

struct TripEntryDetail: View {
    let tripID: UUID
    let entryID: UUID
    @Environment(TripDetailStore.self) private var store
    @State private var editing = false

    var body: some View {
        if let document = try? store.document(for: tripID),
           let entry = document.entries.first(where: { $0.id == entryID }) {
            Form {
                Section("詳細") {
                    LabeledContent("名前", value: entry.title)
                    LabeledContent("種類", value: entry.kind.title)
                    if !entry.category.isEmpty { LabeledContent("カテゴリ", value: entry.category) }
                    if !entry.reservationNumber.isEmpty { LabeledContent("予約番号", value: entry.reservationNumber) }
                    if entry.kind == .flight {
                        LabeledContent("出発空港", value: entry.departureAirport)
                        LabeledContent("到着空港", value: entry.arrivalAirport)
                        LabeledContent("航空会社", value: entry.airline)
                        LabeledContent("便名", value: entry.flightNumber)
                    }
                    if entry.kind != .spot {
                        LabeledContent(entry.kind == .hotel ? "チェックイン" : "開始・出発", value: entry.dateText())
                        LabeledContent(entry.kind == .hotel ? "チェックアウト" : "終了・到着", value: entry.dateText(arrival: true))
                    }
                }
                .listRowBackground(Color("TripPanel"))
                if entry.kind != .flight {
                    Section("場所") {
                        Text(entry.address.isEmpty ? "住所未登録" : entry.address)
                        if let url = entry.mapURL {
                            Link("Apple Mapsで開く", destination: url)
                        } else {
                            Text(store.isOwner(of: tripID) ? "編集から住所または座標を追加してください。" : "作成者が住所または座標を追加すると地図を開けます。")
                                .foregroundStyle(Color("TripSecondaryInk"))
                        }
                    }
                    .listRowBackground(Color("TripPanel"))
                }
                if entry.kind == .flight {
                    Section("参加者ごとの座席") {
                        ForEach(document.members) { member in
                            let seat = document.seats.first { $0.bookingID == entryID && $0.memberID == member.id }?.seat ?? ""
                            if store.isOwner(of: tripID) || member.id == store.currentUserID {
                                NavigationLink {
                                    SeatEditor(tripID: tripID, bookingID: entryID, member: member, initialSeat: seat)
                                } label: {
                                    LabeledContent(member.name, value: seat.isEmpty ? "未設定" : seat)
                                }
                                .accessibilityIdentifier(member.id == store.currentUserID ? "edit-own-seat" : "edit-member-seat")
                            } else {
                                LabeledContent(member.name, value: seat.isEmpty ? "未設定" : seat)
                            }
                        }
                    }
                    .listRowBackground(Color("TripPanel"))
                }
            }
            .navigationTitle(entry.kind.title)
            .modifier(TripPageStyle())
            .toolbar {
                if store.isOwner(of: tripID) {
                    Button("編集") { editing = true }
                        .accessibilityIdentifier("edit-common-entry")
                }
            }
            .sheet(isPresented: $editing) {
                NavigationStack { TripEntryEditor(tripID: tripID, initial: entry, isNew: false) }
            }
        } else {
            ContentUnavailableView("項目を開けません", systemImage: "lock")
        }
    }
}

private struct SeatEditor: View {
    let tripID: UUID
    let bookingID: UUID
    let member: TripMember
    @State private var seat: String
    @State private var errorMessage: String?
    @Environment(TripDetailStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    init(tripID: UUID, bookingID: UUID, member: TripMember, initialSeat: String) {
        self.tripID = tripID
        self.bookingID = bookingID
        self.member = member
        _seat = State(initialValue: initialSeat)
    }

    var body: some View {
        Form {
            Section {
                TextField("座席（例：12A）", text: $seat).accessibilityIdentifier("seat-field")
            } header: {
                Text(member.name)
            } footer: {
                Text("空欄で保存すると座席の割り当てを解除します。")
            }
            .listRowBackground(Color("TripPanel"))
            if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            Button("座席を保存") {
                do {
                    try store.saveSeat(seat, bookingID: bookingID, memberID: member.id, tripID: tripID)
                    dismiss()
                } catch { errorMessage = error.localizedDescription }
            }
            .accessibilityIdentifier("save-seat")
        }
        .navigationTitle("座席を編集")
        .modifier(TripPageStyle())
    }
}
