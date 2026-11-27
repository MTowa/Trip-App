import SwiftUI

struct SettingsPage: View {
    var body: some View {
        Form {
            Section("旅行中の設定") {
                pending("24時間表示", message: "旅程の時刻を24時間で表示します", symbol: "clock")
                pending("予定の通知", message: "予定の前に通知を受け取ります", symbol: "calendar")
            }
            .listRowBackground(Color("TripPanel"))
            Section("写真") {
                pending("写真を元の画質で保存", message: "旅行の写真を元の画質で保存します", symbol: "photo")
            }
            .listRowBackground(Color("TripPanel"))
            Section("プライバシー") {
                pending("写真の位置情報を共有", message: "同行者に写真の撮影場所を共有します", symbol: "shield")
            }
            .listRowBackground(Color("TripPanel"))
            Section {
                pending("別のアカウントを作成", message: "アカウント登録機能は準備中です", symbol: "person.crop.circle.badge.plus")
            }
            .listRowBackground(Color("TripPanel"))
            Section("保存について") {
                Label("この端末に保存", systemImage: "iphone")
                Text("旅行とプロフィールは端末内に保存されます。端末間の同期や友だちへの共有には対応していません。")
                Text("アプリを削除すると、保存したデータも削除されます。")
                    .foregroundStyle(Color("TripSecondaryInk"))
            }
            .listRowBackground(Color("TripPanel"))
            Section("表示") {
                Text("文字サイズと外観は、iPhoneの設定に合わせて変わります。")
            }
            .listRowBackground(Color("TripPanel"))
            Section("アプリについて") {
                LabeledContent("アプリ名", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Trip App")
                LabeledContent("バージョン", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
            }
            .listRowBackground(Color("TripPanel"))
        }
        .navigationTitle("設定")
        .modifier(TripPageStyle())
    }

    private func pending(_ title: LocalizedStringKey, message: LocalizedStringKey, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            TripInfoRow(title: title, message: message, symbol: symbol)
            Text("準備中")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("TripSecondaryInk"))
                .padding(.leading, 56)
                .padding(.bottom, 8)
        }
        .accessibilityElement(children: .combine)
    }
}
