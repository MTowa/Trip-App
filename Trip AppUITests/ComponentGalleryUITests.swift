import XCTest

final class ComponentGalleryUITests: XCTestCase {
    @MainActor
    func testTabNavigationAndEmptyStateAction() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--component-gallery"]
        app.launch()

        XCTAssertTrue(app.navigationBars["コンポーネント"].waitForExistence(timeout: 10))
        app.tabBars.buttons["旅行一覧"].tap()
        XCTAssertTrue(app.staticTexts["旅行がありません"].waitForExistence(timeout: 5))
        app.buttons["empty-state-action"].tap()
        XCTAssertTrue(app.switches["デモ写真を使用"].waitForExistence(timeout: 5))
        app.switches["デモ写真を使用"].tap()

        app.tabBars.buttons["プロフィール"].tap()
        XCTAssertTrue(app.images["プロフィール画像未設定"].exists)
        app.tabBars.buttons["ホーム"].tap()
        app.buttons["旅程"].tap()
        XCTAssertTrue(app.navigationBars["旅程"].waitForExistence(timeout: 5))
        app.buttons["閉じる"].tap()
        XCTAssertTrue(app.navigationBars["コンポーネント"].exists)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Stage 2 component gallery"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
