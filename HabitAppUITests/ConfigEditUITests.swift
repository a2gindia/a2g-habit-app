import XCTest

/// Editing the daily focus target updates the daily potential the dashboard
/// measures against (and persists via the config row).
final class ConfigEditUITests: XCTestCase {

    override func setUp() { continueAfterFailure = false }

    func testEditingTargetUpdatesDashboardPotential() {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting"]
        app.launchEnvironment = ["SEED_DEMO_GOAL": "1"]     // no logs → gain, kept ₹0
        app.launch()

        // Default target 240 min × ₹380.52/min = ₹91,324 potential.
        XCTAssertTrue(app.staticTexts["of ₹91,324 possible"].waitForExistence(timeout: 10))

        app.buttons["dashboard.editConfig"].tap()
        // SwiftUI names the stepper's controls "<id>-Increment"/"-Decrement".
        let increment = app.buttons["config.target-Increment"]
        XCTAssertTrue(increment.waitForExistence(timeout: 5), "Settings sheet should show the focus-target stepper")
        increment.tap()                                     // 240 → 255 min
        app.buttons["config.save"].tap()

        // Dashboard potential reflects the new target: 255 × ₹380.52 = ₹97,032.
        expectation(for: NSPredicate(format: "label == %@", "of ₹97,032 possible"),
                    evaluatedWith: app.staticTexts["of ₹97,032 possible"])
        waitForExpectations(timeout: 6)
    }
}
