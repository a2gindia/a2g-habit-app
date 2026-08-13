import XCTest

/// Drives the real slice-2 flow through the UI: honesty screen → goal setup →
/// dashboard, asserting the time-value rate the engine computes actually reaches
/// the screen. Runs headlessly via `xcodebuild test` (no native panel needed).
final class OnboardingFlowUITests: XCTestCase {

    override func setUp() { continueAfterFailure = false }

    func testOnboardingToDashboardShowsRate() {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting"]   // clean in-memory store
        app.launch()

        // Honesty screen is first, before any number.
        let understand = app.buttons["honesty.continue"]
        XCTAssertTrue(understand.waitForExistence(timeout: 10), "Honesty screen should show first")
        understand.tap()

        // Goal setup pre-fills valid defaults (₹100cr / 5y / calendar hours).
        // (The live per-hour preview lives in a lazily-rendered Form section that
        // may be off-screen, so we assert the rate on the dashboard instead.)
        let start = app.buttons["goal.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5), "Goal setup should appear")
        start.tap()

        // Dashboard appears — the framed headline is present (gain, ₹0 with no
        // logs yet) — and still renders the per-hour rate.
        XCTAssertTrue(app.staticTexts["headline.amount"].waitForExistence(timeout: 10),
                      "Dashboard should appear after saving the goal")
        let perHour = app.staticTexts["dashboard.perHour"]
        XCTAssertTrue(perHour.waitForExistence(timeout: 5))
        XCTAssertEqual(perHour.label, "₹22,831")
    }
}
