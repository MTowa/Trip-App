# 工程2の共通コンポーネント

## コンポーネントと責務

| 型 | 用途 |
| --- | --- |
| TripCardView | 横長の旅行カード。都市名・期間・同行者・表紙を表示 |
| PastTripCardView | 写真が上にある縦長カード。過去の旅行などに使用 |
| DestinationCover | 画像表示と共通表紙へのフォールバック |
| TripSectionButton | 旅程・スポット・予約情報へのアクション |
| TripTabContainer | 5タブの標準TabViewと各タブのNavigationStack |
| TripEmptyStateView | データが空の場合の説明とアクション |
| ProfileAvatarView | 人物写真未設定の標準アイコン |
| Destination / DestinationCatalog | 都市・画像・出典のデータ形式と検証 |
| ComponentGallery | DEBUG専用のサンプル表示・操作確認 |

部品は保存処理を持たず、入力データと呼び出し側のアクションを受け取ります。カードを開く処理は工程3でNavigationLinkなどから接続します。dateTextには呼び出し側で対象ロケール・旅行の日付に合わせた期間文字列を渡します。ギャラリーの日付はFigmaのサンプル表示です。

## Figmaとの対応

日本語ページの以下のノードを確認しました。

| Figmaノード | 実装 |
| --- | --- |
| 23:4526 Trip Card · Paris | TripCardView |
| 23:4543 Past trip · Kyoto | PastTripCardView |
| 23:4539 Open itinerary | TripSectionButton |
| 23:4525 メニューバー | TripTabContainer |

横長カードの角丸30pt、縦長カードの角丸19pt、写真部分の角丸14pt、青いアクセント（#204F74）とカード面（#FDFBF5）を反映しています。色はアセットカタログにまとめ、ダークモード用の値も用意しました。

開発指示書を優先して、メニューバーは独自描画せずTabView、アイコンはSF Symbolsを使用します。Figmaの固定サイズ・固定座標や独自フォントはそのまま移植せず、システムのテキストスタイルで文字サイズの変更に追従させています。表紙上の暗いオーバーレイで文字を読みやすくしています。

写真はFigmaから取得したデモ用画像です。実際の都市画像は別途提供されるデータに差し替えるため、部品はアセット名を入力として受け取ります。

## SF Symbolsの最低対応OS

AppleがOSに同梱するCoreGlyphsの name_availability.plist（symbols / year_to_release）で採用名を確認しました。全てiOS 17以前から利用可能です。実行中のSDKで画像が生成されることも単体テストで確認します。

| シンボル | 導入iOS | 用途 |
| --- | --- | --- |
| house | 13 | ホーム |
| rectangle.stack | 13 | 旅行一覧 |
| plus.app | 13 | 旅を追加 |
| person | 13 | プロフィール |
| gearshape | 14 | 設定 |
| calendar | 13 | 旅程 |
| mappin.and.ellipse | 13 | スポット |
| ticket | 14 | 予約情報 |
| person.crop.circle.fill | 13 | プロフィールの初期画像 |
| person.2.fill | 13 | 同行者 |
| globe | 13 | 未登録画像の共通表紙 |
| suitcase | 15 | 旅行が空の状態 |

iOS 17ランタイムでの実行検証は別途必要です。

## 確認方法

ComponentGalleryの3つのPreview、またはDebug起動引数 `--component-gallery` で確認します。

1. ホームの横長・縦長カードと、写真のない共通表紙を確認する。
2. 旅程・スポット・予約情報のボタンで確認用シートが開閉する。
3. 旅行一覧の空表示から「旅を追加」でタブが切り替わる。
4. 「デモ写真を使用」の切替で写真と共通表紙が入れ替わる。
5. プロフィールでは標準アイコンが表示される。
6. ダークモード、最大文字サイズで文字の欠け・重なりがないことを確認する。大きい文字ではカードとボタンを1列にする。

カードは読み上げ要素をまとめ、背景写真・共通表紙の装飾は読み上げ対象外です。操作ボタンには日本語ラベルを付けています。VoiceOverの実機読み上げ検証は工程3で主要画面を接続した後に行います。
