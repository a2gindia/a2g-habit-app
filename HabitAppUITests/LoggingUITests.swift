import XCTest

/// Verifies logging actually records events and the flat, factual counters update
/// — a build completion, a duration-based deep-work session, and a break-habit
/// slip (which must log without any error/shame and without blocking).
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

    func testLoggingASlipRecordsItNeutrally() {
        let app = launchIntoLog()
        app.buttons["log.cigarette"].tap()
        XCTAssertTrue(app.staticTexts["1× today"].waitForExistence(timeout: 5),
                      "Slip should record a neutral count")
        // A second slip increments — logging never blocks.
        app.buttons["log.cigarette"].tap()
        XCTAssertTrue(app.staticTexts["2× today"].waitForExistence(timeout: 5))
    }

    func testLoggingABuildCompletion() {
        let app = launchIntoLog()
        app.buttons["log.workout"].tap()
        XCTAssertTrue(app.staticTexts["done 1×"].waitForExistence(timeout: 5))
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
