import XCTest

/// The info button on Today opens the how-it-works guide.
final class GuideUITests: XCTestCase {

    override func setUp() { continueAfterFailure = false }

    func testHelpGuideOpensAndCloses() {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting"]
        app.launchEnvironment = ["SEED_DEMO_GOAL": "1"]
        app.launch()

        app.buttons["dashboard.help"].tap()
        XCTAssertTrue(app.staticTexts["How it works"].waitForExistence(timeout: 5),
                      "Guide should open")
        XCTAssertTrue(app.staticTexts["Time is the number."].exists,
                      "Guide should explain the core idea")
        app.buttons["guide.done"].tap()
        XCTAssertFalse(app.staticTexts["How it works"].waitForExistence(timeout: 2))
    }
}
