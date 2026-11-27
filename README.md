# Trip App

旅行前に同行者と準備し、旅行中に旅程・スポット・予約情報を確認する、iPhone向けのデジタルしおりです。旅のメモ欄は設けません。

## 開発環境

| 項目 | 設定 |
| --- | --- |
| Xcode | 27.2（27B52） |
| 最低対応OS | iOS 17.0 |
| 初期対応言語 | 日本語 |
| UI | SwiftUI |
| 端末内保存 | 工程3〜4でSwiftDataを導入予定 |
| リポジトリ | https://github.com/MTowa/Trip-App |
| スキーム | Trip App（共有） |

現在は工程2の共通コンポーネントまで実装しています。旅行画面、永続化、認証、共有はまだ実装していません。認証・共有バックエンドは工程5の着手前に決定します。

このプロジェクトはXcodeのJSON形式（project.xcproj）を使用しています。開発環境の差を避けるため、Xcode 27.2を使用してください。最低対応iOSと開発用Xcodeのバージョンは別です。

## 起動

1. リポジトリをクローンします。

   ```sh
   git clone https://github.com/MTowa/Trip-App.git
   cd Trip-App
   ```

2. PRを検証する場合は対象ブランチに切り替えます。工程2のレビュー中は `git switch stage-2-feat-trip-components` を実行してください。
3. `Trip App.xcodeproj` をXcode 27.2で開きます。
4. スキーム「Trip App」とインストール済みのiPhoneシミュレーターを選択します。
5. ⌘Rで起動します。初期画面はXcodeテンプレートの「Hello, world!」です。

外部パッケージ、APIキー、バックエンドへの接続は不要です。シミュレーター起動にApple Developerのチーム設定は不要です。実機で実行する場合はSigning & Capabilitiesで自身のチームを設定してください。個人の認証情報はコミットしないでください。

## ビルド・検証

Xcodeで⌘Bを実行するとビルド、⌘Uを実行すると共有スキームに含まれる単体テストとUIテストを実行できます。

コマンドラインではXcode Settings > LocationsのCommand Line ToolsをXcode 27.2に設定したうえで、次の手順を使用できます。

```sh
xcodebuild -version
xcodebuild -project "Trip App.xcodeproj" -scheme "Trip App" -showdestinations
xcodebuild -project "Trip App.xcodeproj" -scheme "Trip App" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 18 Pro' build
xcodebuild -project "Trip App.xcodeproj" -scheme "Trip App" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 18 Pro' test
```

端末名は、表示された利用可能なiPhoneシミュレーター名に置き換えてください。iOS 17対応の設定だけでは、iOS 17での実行検証を代替できません。対応するランタイムまたは実機での検証は別途必要です。

工程2では都市データの検証・画像とシンボルの存在確認をSwift Testingで、ギャラリーの操作をXCUIAutomationで追加しています。初期テンプレートのテストも残っています。旅行機能の動作を保証するものではなく、各機能の実装時に必要な検証を追加します。

## 名前と設定

ホーム画面に表示する名前は、アプリターゲットの `INFOPLIST_KEY_CFBundleDisplayName` にまとめています。現状は「Trip App」です。今後アプリ内で名前を表示する際もBundleの表示名を参照します。

GitHubリポジトリ名、Xcodeターゲット名、Bundle Identifierはそれぞれ独立して管理します。表示名変更だけでBundle Identifierを変更しないでください。

## 共通コンポーネントの確認（工程2）

`ComponentGallery.swift` のPreviewから、標準表示・文字サイズ最大・ダークモードを確認できます。シミュレーターで操作する場合は、Product > Scheme > Edit Scheme > Run > Argumentsに `--component-gallery` を追加してDebugで実行します。確認後は引数を外してください。ギャラリーはDEBUG専用で、デモデータを保存・共有しません。

- [都市画像の仕様と記入例](docs/destination-images.md)
- [コンポーネント一覧・デザインとの対応](docs/components.md)
- [ブランチ・PR命名規則](docs/development-workflow.md)

## 開発の進め方

[ブランチ・PR命名規則とレビュー手順](docs/development-workflow.md)を参照してください。

1. Git管理・開発環境・起動手順の整備。
2. Figmaを確認し、Trip Cardなどの共通コンポーネントと都市画像のデータ仕様を作成。
3. ホーム・旅行一覧・旅の追加・プロフィール・設定と端末内保存を実装。
4. 旅程・スポット・予約情報の追加・編集を実装。参加者が編集できる項目は着手前に確認。
5. 署名・権限・認証方式・バックエンド・検証環境を確認後、登録と認証・共有を実装。

工程6以降は工程5完了後に提案します。各工程はブランチとPRに分け、依頼者の確認後にmainへ取り込みます。

## 参考

- [Figma「Trip App」日本語版](https://www.figma.com/design/AJEvMky8mpUz14PpYtoerS/Trip-App?node-id=23-4453)
- [Apple Human Interface Guidelines](https://developer.apple.com/jp/design/human-interface-guidelines/)
