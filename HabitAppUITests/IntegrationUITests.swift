import XCTest

/// End-to-end wiring: logging changes the framed headline, and mood records.
final class IntegrationUITests: XCTestCase {

    override func setUp() { continueAfterFailure = false }

    private func launchSeeded() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting"]
        app.launchEnvironment = ["SEED_DEMO_GOAL": "1"]
        app.launch()
        return app
    }

    func testHeadlineUpdatesAfterLoggingDeepWork() {
        let app = launchSeeded()
        // Week 0 → gain framing. No logs yet → kept ₹0.
        let headline = app.staticTexts["headline.amount"]
        XCTAssertTrue(headline.waitForExistence(timeout: 10))
        XCTAssertEqual(headline.label, "₹0")

        // Log a deep-work session.
        app.tabBars.buttons["Log"].tap()
        app.buttons["log.deep-work-block"].tap()
        app.buttons["duration.log"].tap()

        // Back on Today, the kept headline should no longer be ₹0.
        app.tabBars.buttons["Today"].tap()
        let notZero = NSPredicate(format: "label != %@", "₹0")
        expectation(for: notZero, evaluatedWith: app.staticTexts["headline.amount"])
        waitForExpectations(timeout: 6)
    }

    func testMoodRecords() {
        let app = launchSeeded()
        let mood4 = app.buttons["mood.4"]
        XCTAssertTrue(mood4.waitForExistence(timeout: 10))
        mood4.tap()
        expectation(for: NSPredicate(format: "isSelected == true"), evaluatedWith: mood4)
        waitForExpectations(timeout: 5)
    }
}
