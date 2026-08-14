import XCTest

/// Insights → History → a day's detail is reachable and renders.
final class HistoryUITests: XCTestCase {

    override func setUp() { continueAfterFailure = false }

    func testHistoryToDayDetail() {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting"]
        app.launchEnvironment = ["SEED_DEMO_GOAL": "1"]   // Today's onAppear records one day
        app.launch()

        app.tabBars.buttons["Insights"].tap()
        let history = app.buttons["insights.history"]
        XCTAssertTrue(history.waitForExistence(timeout: 10), "Insights should link to history")
        history.tap()

        let day = app.buttons["history.day"].firstMatch
        XCTAssertTrue(day.waitForExistence(timeout: 5), "History should list at least one day")
        day.tap()

        XCTAssertTrue(app.staticTexts["detail.amount"].waitForExistence(timeout: 5),
                      "Day detail should show the framed amount")
    }
}
