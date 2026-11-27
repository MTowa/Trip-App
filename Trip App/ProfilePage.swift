import SwiftUI

struct ProfilePage: View {
    let repository: TripRepository
    @State private var editing = false

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    ProfileAvatarView()
                    Text(repository.displayName)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
                Button("プロフィールを編集") { editing = true }
            }
            Section("友だち") {
                NavigationLink("友だち追加") {
                    ContentUnavailableView(
                        "友だちと旅を共有",
                        systemImage: "person.2",
                        description: Text("友だち追加はアカウント登録機能の公開後に利用できます。現在の旅行はこの端末だけに保存されます。")
                    )
                    .navigationTitle("友だち追加")
                }
            }
        }
        .navigationTitle("プロフィール")
        .sheet(isPresented: $editing) {
            ProfileEditor(repository: repository, initialName: repository.displayName)
        }
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

struct SettingsPage: View {
    var body: some View {
        Form {
            Section("保存について") {
                Label("この端末に保存", systemImage: "iphone")
                Text("旅行とプロフィールは端末内に保存されます。端末間の同期や友だちへの共有には対応していません。")
                Text("アプリを削除すると、保存したデータも削除されます。")
                    .foregroundStyle(.secondary)
            }
            Section("表示") {
                Text("文字サイズと外観は、iPhoneの設定に合わせて変わります。")
            }
            Section("アプリについて") {
                LabeledContent("アプリ名", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Trip App")
                LabeledContent("バージョン", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
            }
        }
        .navigationTitle("設定")
    }
}
