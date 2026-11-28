import XCTest

final class TripDetailUITests: XCTestCase {
    @MainActor
    func testOwnerAddsAndEditsSpotAndAssignsParticipantSeat() throws {
        let app = launch("--details-preview")
        app.buttons["スポット"].tap()
        XCTAssertTrue(app.buttons["add-detail"].waitForExistence(timeout: 5))
        app.buttons["add-detail"].tap()
        enter("Kyoto Station", into: app.descendants(matching: .any)["entry-title"].firstMatch, app: app)
        app.buttons["save-entry-toolbar"].tap()
        let row = app.buttons["detail-entry"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.staticTexts["住所未登録"].waitForExistence(timeout: 5))
        app.buttons["edit-common-entry"].tap()
        enter("Kyoto Japan", into: app.descendants(matching: .any)["entry-address"].firstMatch, app: app)
        app.buttons["save-entry-toolbar"].tap()
        XCTAssertTrue(app.links["Apple Mapsで開く"].waitForExistence(timeout: 5)
                      || app.buttons["Apple Mapsで開く"].exists)
        capture(app, "スポット")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.segmentedControls.buttons["予約情報"].tap()
        app.buttons["detail-entry"].firstMatch.tap()
        reveal(app.buttons["edit-member-seat"], in: app)
        app.buttons["edit-member-seat"].tap()
        enter("12A", into: app.textFields["seat-field"], app: app)
        app.buttons["save-seat"].tap()
        reveal(app.buttons["edit-member-seat"], in: app)
        XCTAssertTrue(app.buttons["edit-member-seat"].label.contains("12A"))
        capture(app, "作成者の座席割当")
    }

    @MainActor
    func testParticipantCanEditOnlyOwnSeat() throws {
        try participantFlow(large: false)
    }

    @MainActor
    func testParticipantWithLargestTextAndDarkAppearance() throws {
        try participantFlow(large: true)
    }

    @MainActor
    private func participantFlow(large: Bool) throws {
        let app = launch("--participant-preview", extra: large ? ["--large-text", "--dark-mode"] : [])
        reveal(app.buttons["予約情報"], in: app)
        app.buttons["予約情報"].tap()
        XCTAssertTrue(app.buttons["detail-entry"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["add-detail"].exists)
        app.buttons["detail-entry"].firstMatch.tap()
        XCTAssertFalse(app.buttons["edit-common-entry"].exists)
        XCTAssertFalse(app.buttons["edit-member-seat"].exists)
        reveal(app.buttons["edit-own-seat"], in: app)
        app.buttons["edit-own-seat"].tap()
        enter("14C", into: app.textFields["seat-field"], app: app)
        reveal(app.buttons["save-seat"], in: app)
        app.buttons["save-seat"].tap()
        reveal(app.buttons["edit-own-seat"], in: app)
        XCTAssertTrue(app.buttons["edit-own-seat"].label.contains("14C"))
        capture(app, large ? "参加者・最大文字ダーク" : "参加者の座席")
    }

    @MainActor
    private func launch(_ preview: String, extra: [String] = []) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [preview] + extra
        app.launch()
        XCTAssertTrue(app.buttons["trip-card"].firstMatch.waitForExistence(timeout: 10))
        return app
    }

    @MainActor
    private func enter(_ value: String, into field: XCUIElement, app: XCUIApplication) {
        reveal(field, in: app)
        field.tap()
        field.typeText(value)
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<12 {
            if element.exists && element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.exists && element.isHittable)
    }

    @MainActor
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "工程4 " + name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
