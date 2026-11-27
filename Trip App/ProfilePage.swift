import SwiftUI

struct ProfilePage: View {
    let repository: TripRepository
    @State private var editing = false
    @Environment(\.dynamicTypeSize) private var typeSize

    private var visitedPlaces: [String] {
        Array(Set(repository.trips.filter { $0.endDate < TripDates.today }.map(\.destination))).sorted()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(spacing: 16) {
                    ProfileAvatarView(size: 144)
                    Text(repository.displayName).font(.title2.bold())
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)

                let layout = typeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(spacing: 20))
                    : AnyLayout(HStackLayout(spacing: 12))
                layout {
                    statistic("旅行回数", value: String(repository.trips.count))
                    statistic("訪問した国", value: "—", explanation: "国の情報は未登録です")
                    statistic("同行者", value: "—", explanation: "同行者の登録機能は準備中です")
                }
                .padding(16)
                .background(Color("TripPanel"), in: RoundedRectangle(cornerRadius: 19))

                VStack(alignment: .leading, spacing: 16) {
                    TripHeading(title: "訪れた場所")
                    if visitedPlaces.isEmpty {
                        Text("旅行が終わると、訪れた都市が表示されます。")
                            .foregroundStyle(Color("TripSecondaryInk"))
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: typeSize.isAccessibilitySize ? 240 : 140))], alignment: .leading) {
                            ForEach(visitedPlaces, id: \.self) { place in
                                Label(place, systemImage: "globe.asia.australia")
                                    .font(.headline)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color("TripPreviewSurface"), in: RoundedRectangle(cornerRadius: 16))
                            }
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 16) {
                    TripHeading(title: "一緒に旅した人")
                    Text("同行者の登録は、アカウント登録機能の公開後に利用できます。")
                        .foregroundStyle(Color("TripSecondaryInk"))
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color("TripPanel"), in: RoundedRectangle(cornerRadius: 19))
                }
            }
            .padding(.horizontal, 25)
            .padding(.bottom, 24)
        }
        .navigationTitle("プロフィール")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink { FriendAvailabilityView() } label: {
                    Label("友だち追加", systemImage: "person.badge.plus")
                }
                .accessibilityLabel("友だち追加")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("プロフィールを編集", systemImage: "pencil") { editing = true }
            }
        }
        .modifier(TripPageStyle())
        .sheet(isPresented: $editing) {
            ProfileEditor(repository: repository, initialName: repository.displayName)
        }
    }

    private func statistic(_ title: LocalizedStringKey, value: String, explanation: String? = nil) -> some View {
        VStack(spacing: 6) {
            Text(value).font(.title2.bold())
            Text(title).font(.caption)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityValue(explanation ?? value)
    }
}

struct FriendAvailabilityView: View {
    var body: some View {
        ContentUnavailableView(
            "友だちと旅を共有",
            systemImage: "person.2",
            description: Text("友だち追加はアカウント登録機能の公開後に利用できます。現在の旅行はこの端末だけに保存されます。")
        )
        .navigationTitle("友だち追加")
        .modifier(TripPageStyle())
    }
}

private struct ProfileEditor: View {
    let repository: TripRepository
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var errorMessage: String?

    init(repository: TripRepository, initialName: String) {
        self.repository = repository
        _name = State(initialValue: initialName)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("表示名", text: $name)
                        .accessibilityIdentifier("profile-name")
                } footer: {
                    Text("1〜40文字で入力してください。")
                }
            }
            .modifier(TripPageStyle())
            .navigationTitle("プロフィール編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        do {
                            try repository.updateProfile(name: name)
                            dismiss()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
    }
}
