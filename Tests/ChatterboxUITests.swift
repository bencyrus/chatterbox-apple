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
    
    // MARK: - Recording Flow Tests
    
    func testRecordingFlow() {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to subjects tab
        let subjectsTab = app.tabBars.buttons[Strings.Tabs.subjects]
        XCTAssertTrue(subjectsTab.waitForExistence(timeout: 5))
        subjectsTab.tap()
        
        // Tap on first cue
        let firstCue = app.staticTexts.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "subjects.cue.")
        ).firstMatch
        XCTAssertTrue(firstCue.waitForExistence(timeout: 5))
        firstCue.tap()
        
        // Wait for cue detail view
        XCTAssertTrue(app.navigationBars[Strings.CueDetail.title].waitForExistence(timeout: 5))
        
        // Check for recording controls (assuming mic permission granted)
        // Note: In actual test, may need to handle permission dialog
        let recordButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "record")
        ).firstMatch
        
        if recordButton.waitForExistence(timeout: 3) {
            // Start recording
            recordButton.tap()
            
            // Wait a moment for recording to start
            sleep(2)
            
            // Look for pause button (indicates recording is active)
            let pauseButton = app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] %@", "pause")
            ).firstMatch
            
            if pauseButton.exists {
                pauseButton.tap()
                
                // After pausing, should see save and delete buttons
                let saveButton = app.buttons[Strings.Recording.saveButton]
                let deleteButton = app.buttons[Strings.Recording.deleteButton]
                
                XCTAssertTrue(saveButton.waitForExistence(timeout: 2))
                XCTAssertTrue(deleteButton.exists)
            }
        }
    }
    
    // MARK: - History Navigation Tests
    
    func testHistoryNavigation() {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to history tab
        let historyTab = app.tabBars.buttons[Strings.Tabs.history]
        XCTAssertTrue(historyTab.waitForExistence(timeout: 5))
        historyTab.tap()
        
        // Check if history items exist
        let historyItems = app.scrollViews.otherElements.descendants(matching: .button)
        
        if historyItems.count > 0 {
            // Tap first history item
            let firstItem = historyItems.firstMatch
            if firstItem.waitForExistence(timeout: 3) {
                firstItem.tap()
                
                // Should navigate to cue detail
                XCTAssertTrue(app.navigationBars[Strings.CueDetail.title].waitForExistence(timeout: 5))
                
                // Should show recording history for this cue
                let recordingHistory = app.staticTexts[Strings.Recording.historySectionTitle]
                XCTAssertTrue(recordingHistory.waitForExistence(timeout: 3))
            }
        } else {
            // If no recordings, should see empty state
            let emptyState = app.staticTexts[Strings.History.emptyState]
            XCTAssertTrue(emptyState.exists || emptyState.waitForExistence(timeout: 2))
        }
    }
    
    // MARK: - Settings Language Change Test
    
    func testSettingsLanguageChange() {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to settings
        let settingsTab = app.tabBars.buttons[Strings.Tabs.settings]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()
        
        // Tap language picker button
        let languageButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", Strings.Settings.languagePickerTitle)
        ).firstMatch
        
        if languageButton.waitForExistence(timeout: 3) {
            languageButton.tap()
            
            // Language picker sheet should appear
            XCTAssertTrue(app.navigationBars[Strings.Settings.languagePickerTitle].waitForExistence(timeout: 3))
            
            // Check that language options are visible
            let languageOptions = app.buttons.matching(
                NSPredicate(format: "identifier BEGINSWITH %@", "language.")
            )
            
            // Should have multiple language options
            XCTAssertGreaterThan(languageOptions.count, 0)
            
            // Dismiss by tapping first option or going back
            if languageOptions.count > 0 {
                languageOptions.element(boundBy: 0).tap()
                
                // Sheet should dismiss
                sleep(1)
                XCTAssertFalse(app.navigationBars[Strings.Settings.languagePickerTitle].exists)
            }
        }
    }
    
    // MARK: - Complete User Journey Test
    
    func testCompleteUserJourney() {
        let app = XCUIApplication()
        app.launch()
        
        // Assuming authenticated session
        // 1. Browse subjects
        let subjectsTab = app.tabBars.buttons[Strings.Tabs.subjects]
        XCTAssertTrue(subjectsTab.waitForExistence(timeout: 5))
        subjectsTab.tap()
        
        // 2. Shuffle cues
        let shuffleButton = app.buttons["subjects.shuffle"]
        if shuffleButton.waitForExistence(timeout: 2) {
            shuffleButton.tap()
            sleep(1) // Wait for shuffle to complete
        }
        
        // 3. View history
        let historyTab = app.tabBars.buttons[Strings.Tabs.history]
        historyTab.tap()
        XCTAssertTrue(historyTab.isSelected)
        
        // 4. Go to settings
        let settingsTab = app.tabBars.buttons[Strings.Tabs.settings]
        settingsTab.tap()
        XCTAssertTrue(settingsTab.isSelected)
        
        // 5. Verify settings screen loaded
        let settingsTitle = app.staticTexts[Strings.Settings.title]
        XCTAssertTrue(settingsTitle.exists || settingsTitle.waitForExistence(timeout: 2))
    }
}


