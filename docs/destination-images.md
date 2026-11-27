# 都市と表紙画像のデータ仕様

都市マスタはUTF-8のJSONで受け取ります。画像ファイルを別途添付し、アセットカタログへ登録します。旅行は表示名ではなく固定の都市IDを参照します。

## 必須項目

| フィールド | 型 | 用途 |
| --- | --- | --- |
| schemaVersion | 整数 | 現在は1 |
| destinations | 配列 | 都市一覧。IDは重複不可 |
| id | 文字列 | 固定ID。例: jp-kyoto。表示名変更後も変更しない |
| displayName | 文字列 | 日本語の都市表示名 |
| countryCode | 文字列 | ISO 3166-1 alpha-2。例: JP |
| timeZoneIdentifier | 文字列 | IANA識別子。例: Asia/Tokyo |
| cover | オブジェクトまたはnull | 未登録の場合はnullまたは省略 |

画像がある場合、coverの以下の項目をすべて指定します。

| フィールド | 型 | 用途 |
| --- | --- | --- |
| assetName | 文字列 | Xcodeの画像セット名。拡張子なし |
| fileName | 文字列 | 受け渡す元画像ファイル名。拡張子を含む |
| attribution.creator | 文字列 | 撮影者または権利者 |
| attribution.sourceURL | HTTPS URL | 元画像の出典ページ。画像CDNの一時URLは使用しない |
| attribution.license | 文字列 | ライセンス名・許諾条件 |
| attribution.credit | 文字列 | アプリ内で表示するクレジット文 |

本番画像を追加する際に利用許諾を確認し、クレジット表示が必要なら、その画像を使用する画面から参照できる形で表示します。表紙コンポーネント自体に出典URLの取得・保存は持たせません。

## 1都市分の記入例

[destination-catalog.example.json](destination-catalog.example.json)を使用できます。以下の出典情報は記入方法を示すダミー値です。実在する写真のライセンスを示すものではありません。

```json
{
  "schemaVersion": 1,
  "destinations": [
    {
      "id": "jp-kyoto",
      "displayName": "京都",
      "countryCode": "JP",
      "timeZoneIdentifier": "Asia/Tokyo",
      "cover": {
        "assetName": "CoverKyoto",
        "fileName": "jp-kyoto.jpg",
        "attribution": {
          "creator": "撮影者名（記入例）",
          "sourceURL": "https://example.com/photos/kyoto",
          "license": "利用許諾条件を記入",
          "credit": "写真: 撮影者名（記入例）"
        }
      }
    }
  ]
}
```

## 推奨画像仕様

- JPEG、sRGB、横長3:2、1800×1200px以上を推奨します。
- 目安は1枚1MB以下。画質を確認して圧縮します。透過は不要です。
- 中央を主題にし、重要な被写体を端に置かないでください。横長カードと縦長カードの両方で中央を基準にトリミングします。
- 写真に都市名・日付・ロゴを焼き込まないでください。文字はSwiftUI側で重ねます。
- Xcodeでは `CoverKyoto.imageset` に登録し、Swiftからは `CoverKyoto` を参照します。
- ファイル名は半角英小文字・数字・ハイフンを推奨します。都市IDと対応させてください。

## 未登録時の表示

coverがnull、都市マスタに未登録、指定アセットが存在しない場合は、共通の青いグラデーション表紙を表示します。都市名・日付は写真の有無にかかわらず表示します。文字はDynamic Typeに追従し、カードの高さは内容に応じて増えます。

DestinationCatalog.decodeはバージョン、ID重複、必須情報、タイムゾーン、画像の出典情報を検証します。読み込み元とエラー表示は工程3のデータ層で接続します。

## 工程2のデモ画像

DemoCoverParisとDemoCoverKyotoは、指定FigmaのTrip Cardと過去の旅行カードから取得した表示検証用の画像です。都市マスタへの本番登録ではなく、DEBUG専用のComponentGalleryでだけ参照します。

元写真の撮影者・ライセンスはFigmaの取得結果から確認できていません。本番の都市画像が届いた段階で、出典情報とともに置き換えてください。デモ画像も現状はアセットカタログに含まれるため、配布用アーカイブの作成前に除去または許諾確認が必要です。

- パリ: Figmaノード23:4526
- 京都: Figmaノード23:4543
- [参照Figma](https://www.figma.com/design/AJEvMky8mpUz14PpYtoerS/Trip-App?node-id=23-4453)
