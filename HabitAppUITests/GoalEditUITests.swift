import XCTest

/// Editing the goal after onboarding updates the dashboard's live rate.
final class GoalEditUITests: XCTestCase {

    override func setUp() { continueAfterFailure = false }

    func testEditingDenominatorUpdatesDashboardRate() {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting"]
        app.launchEnvironment = ["SEED_DEMO_GOAL": "1"]   // ₹100cr / 5y / calendar hours
        app.launch()

        let perHour = app.staticTexts["dashboard.perHour"]
        XCTAssertTrue(perHour.waitForExistence(timeout: 10))
        XCTAssertEqual(perHour.label, "₹22,831")          // calendar-hours rate

        app.buttons["dashboard.editGoal"].tap()
        let working = app.buttons["Working"]
        XCTAssertTrue(working.waitForExistence(timeout: 5), "Edit sheet should show the denominator picker")
        working.tap()                                     // 8h × 5d × 5y = 10,400 h
        app.buttons["goal.save"].tap()

        // Dashboard reflects the new working-hours rate.
        expectation(for: NSPredicate(format: "label == %@", "₹96,154"),
                    evaluatedWith: app.staticTexts["dashboard.perHour"])
        waitForExpectations(timeout: 6)
    }
}
