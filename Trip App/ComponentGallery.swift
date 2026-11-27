import SwiftUI

#if DEBUG
/// Isolated fixtures; never inserted into the user's trip storage.
struct ComponentGallery: View {
    @State private var selection = TripTab.home

    var body: some View {
        TripTabContainer(selection: $selection) { tab in
            switch tab {
            case .home:
                CardGallery()
            case .trips:
                TripEmptyStateView(
                    title: "旅行がありません",
                    message: "次の旅行の準備を始めましょう。",
                    systemImage: "suitcase",
                    actionTitle: "旅を追加"
                ) {
                    selection = .addTrip
                }
                .navigationTitle("旅行一覧")
            case .addTrip:
                CoverSelectionGallery()
            case .profile:
                ProfileAvatarView()
                    .navigationTitle("プロフィール")
            case .settings:
                Form {
                    Section("コンポーネントの確認") {
                        Text("表示データはサンプルです。保存・共有されません。")
                    }
                }
                .navigationTitle("設定")
            }
        }
    }
}

private struct CardGallery: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedSection: TripSection?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("デモデータ")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TripCardView(
                    destinationName: "パリ",
                    dateText: "2026.11.24 — 2026.11.27",
                    coverAssetName: "DemoCoverParis",
                    companionNames: ["Mio", "Ren"]
                )
                Text("旅の情報")
                    .font(.title2.bold())
                LazyVGrid(columns: [GridItem(.adaptive(minimum: dynamicTypeSize.isAccessibilitySize ? 240 : 96))]) {
                    ForEach(TripSection.allCases) { section in
                        TripSectionButton(section: section) {
                            selectedSection = section
                        }
                    }
                }
                Text("過去の旅行")
                    .font(.title2.bold())
                LazyVGrid(columns: [GridItem(.adaptive(minimum: dynamicTypeSize.isAccessibilitySize ? 280 : 155))], alignment: .leading) {
                    PastTripCardView(
                        destinationName: "京都",
                        dateText: "2026年9月12日〜14日",
                        coverAssetName: "DemoCoverKyoto"
                    )
                    PastTripCardView(
                        destinationName: "画像未登録の都市",
                        dateText: "2026年8月1日〜3日",
                        coverAssetName: nil
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("コンポーネント")
        .sheet(item: $selectedSection) { section in
            NavigationStack {
                Text("この画面は共通部品の動作確認用です。")
                    .padding()
                    .navigationTitle(section.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("閉じる") { selectedSection = nil }
                        }
                    }
            }
        }
    }
}

private struct CoverSelectionGallery: View {
    @State private var useSampleImage = false

    var body: some View {
        Form {
            Section("表紙の確認") {
                Toggle("デモ写真を使用", isOn: $useSampleImage)
                TripCardView(
                    destinationName: useSampleImage ? "パリ" : "画像未登録の都市",
                    dateText: "2026.11.24 — 2026.11.27",
                    coverAssetName: useSampleImage ? "DemoCoverParis" : nil
                )
                .listRowInsets(EdgeInsets())
            }
        }
        .navigationTitle("旅を追加")
    }
}

#Preview("共通コンポーネント") {
    ComponentGallery()
        .environment(\.locale, Locale(identifier: "ja_JP"))
}

#Preview("文字サイズ最大") {
    ComponentGallery()
        .environment(\.locale, Locale(identifier: "ja_JP"))
        .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("ダークモード") {
    ComponentGallery()
        .environment(\.locale, Locale(identifier: "ja_JP"))
        .preferredColorScheme(.dark)
}
#endif
