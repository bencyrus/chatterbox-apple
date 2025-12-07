import XCTest
@testable import Chatterbox

final class ChatterboxUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLoginScreenRendersAndRequestsMagicLink() {
        let app = XCUIApplication()
        app.launch()

        let identifierField = app.textFields[Strings.A11y.identifierField]
        XCTAssertTrue(identifierField.waitForExistence(timeout: 5))

        identifierField.tap()
        identifierField.typeText("test@example.com")

        let requestButton = app.buttons[Strings.Login.requestLink]
        XCTAssertTrue(requestButton.exists)
        requestButton.tap()
    }

    func testSubjectsAndCueNavigation() {
        let app = XCUIApplication()
        app.launch()

        // Assumes an authenticated session for this test configuration.
        let subjectsTab = app.tabBars.buttons[Strings.Tabs.subjects]
        XCTAssertTrue(subjectsTab.waitForExistence(timeout: 5))
        subjectsTab.tap()

        let shuffle = app.buttons["subjects.shuffle"]
        if shuffle.exists {
            shuffle.tap()
        }

        let firstCue = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@", "subjects.cue.")).firstMatch
        if firstCue.waitForExistence(timeout: 5) {
            firstCue.tap()
            XCTAssertTrue(app.navigationBars[Strings.CueDetail.title].waitForExistence(timeout: 5))
        }
    }

    func testSettingsLanguageAndLogout() {
        let app = XCUIApplication()
        app.launch()

        let settingsTab = app.tabBars.buttons[Strings.Tabs.settings]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()

        let languagePicker = app.otherElements["settings.languagePicker"]
        XCTAssertTrue(languagePicker.waitForExistence(timeout: 5))

        let logoutButton = app.buttons[Strings.Settings.logout]
        XCTAssertTrue(logoutButton.exists)
        logoutButton.tap()
    }
}


