import XCTest

/// Verifies logging records events, the flat counters update, and a mistaken tap
/// can be undone with the minus control.
final class LoggingUITests: XCTestCase {

    override func setUp() { continueAfterFailure = false }

    private func launchIntoLog() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting"]                 // clean in-memory store
        app.launchEnvironment = ["SEED_DEMO_GOAL": "1"]      // seed goal → skip onboarding
        app.launch()
        let logTab = app.tabBars.buttons["Log"]
        XCTAssertTrue(logTab.waitForExistence(timeout: 10), "Log tab should exist")
        logTab.tap()
        return app
    }

    private func expectCount(_ app: XCUIApplication, _ id: String, _ value: String) {
        expectation(for: NSPredicate(format: "label == %@", value),
                    evaluatedWith: app.staticTexts[id])
        waitForExpectations(timeout: 5)
    }

    func testLoggingASlipRecordsItNeutrally() {
        let app = launchIntoLog()
        app.buttons["log.cigarette"].tap()
        expectCount(app, "count.cigarette", "1")
        app.buttons["log.cigarette"].tap()          // logging never blocks
        expectCount(app, "count.cigarette", "2")
    }

    func testLoggingABuildCompletion() {
        let app = launchIntoLog()
        app.buttons["log.workout"].tap()
        expectCount(app, "count.workout", "1")
    }

    func testUndoAMistakenLog() {
        let app = launchIntoLog()
        app.buttons["log.cigarette"].tap()
        app.buttons["log.cigarette"].tap()
        expectCount(app, "count.cigarette", "2")
        app.buttons["unlog.cigarette"].tap()        // undo the mistaken tap
        expectCount(app, "count.cigarette", "1")
    }

    func testDeepWorkDurationEntry() {
        let app = launchIntoLog()
        app.buttons["log.deep-work-block"].tap()
        let confirm = app.buttons["duration.log"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "Duration sheet should appear")
        confirm.tap()   // default 50 min
        XCTAssertTrue(app.staticTexts["50 min today"].waitForExistence(timeout: 5))
    }
}
