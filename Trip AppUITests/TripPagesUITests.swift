import XCTest

final class TripPagesUITests: XCTestCase {
    @MainActor
    func testCreateTripAndEditProfileAcrossTabs() throws {
        try verifyTripFlow(appearanceArguments: [])
    }

    @MainActor
    func testTripFlowWithLargestTextAndDarkAppearance() throws {
        try verifyTripFlow(appearanceArguments: ["--large-text", "--dark-mode"])
    }

    @MainActor
    private func verifyTripFlow(appearanceArguments: [String]) throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"] + appearanceArguments
        app.launch()
        XCTAssertTrue(app.buttons["empty-state-action"].waitForExistence(timeout: 10))
        capture(app, name: "空のホーム")
        app.buttons["empty-state-action"].tap()
        let destination = app.textFields["destination-field"]
        XCTAssertTrue(destination.waitForExistence(timeout: 5))
        destination.tap()
        destination.typeText("Kyoto\n")
        let dates = app.buttons["trip-dates"]
        reveal(dates, in: app)
        dates.tap()
        XCTAssertTrue(app.navigationBars["旅行日程"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.datePickers.count, 2)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        reveal(app.buttons["create-trip"], in: app)
        capture(app, name: "旅行作成")
        app.buttons["create-trip"].tap()
        XCTAssertTrue(app.navigationBars["旅行の概要"].waitForExistence(timeout: 5))
        app.buttons["完了"].tap()
        app.tabBars.buttons["ホーム"].tap()
        let card = app.descendants(matching: .any)["trip-card"].firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        XCTAssertTrue(card.label.contains("Kyoto"))
        capture(app, name: "ホーム")
        app.buttons["すべて見る"].tap()
        card.tap()
        XCTAssertTrue(app.navigationBars["旅行の概要"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.tabBars.buttons["プロフィール"].tap()
        reveal(app.buttons["プロフィールを編集"], in: app)
        app.buttons["プロフィールを編集"].tap()
        let name = app.textFields["profile-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        let existing = name.value as? String ?? ""
        name.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count) + "Towa")
        app.buttons["保存"].tap()
        XCTAssertTrue(app.staticTexts["Towa"].waitForExistence(timeout: 5))
        capture(app, name: "プロフィール")
        app.buttons["プロフィールを編集"].tap()
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText(" changed")
        app.buttons["キャンセル"].tap()
        XCTAssertTrue(app.staticTexts["Towa"].waitForExistence(timeout: 5))
        app.buttons["友だち追加"].tap()
        XCTAssertTrue(app.staticTexts["友だちと旅を共有"].waitForExistence(timeout: 5))
        app.tabBars.buttons["設定"].tap()
        capture(app, name: "設定上部")
        reveal(app.staticTexts["この端末に保存"], in: app)
        capture(app, name: "設定")
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<6 {
            if element.exists && element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.exists && element.isHittable)
    }

    @MainActor
    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "工程3 " + name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
