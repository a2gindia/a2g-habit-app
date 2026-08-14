import XCTest

/// Adding a habit through management makes it appear in the log.
final class HabitManagementUITests: XCTestCase {

    override func setUp() { continueAfterFailure = false }

    func testAddingHabitAppearsInLog() {
        let app = XCUIApplication()
        app.launchArguments = ["-uitesting"]
        app.launchEnvironment = ["SEED_DEMO_GOAL": "1"]
        app.launch()

        app.tabBars.buttons["Log"].tap()
        app.buttons["log.manage"].tap()

        app.buttons["habits.add"].tap()
        app.buttons["New build habit"].tap()

        let name = app.textFields["habit.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5), "New-habit form should show a name field")
        name.tap()
        name.typeText("Meditation")
        app.buttons["habit.save"].tap()

        // Back in the manage list, close it, and confirm it reached the log.
        app.buttons["habits.done"].tap()
        XCTAssertTrue(app.staticTexts["Meditation"].waitForExistence(timeout: 5),
                      "Added habit should appear in the log list")
    }
}
