import Foundation

enum Strings {
    enum Tabs {
        static let subjects = NSLocalizedString("tabs.subjects", comment: "Subjects tab")
        static let history = NSLocalizedString("tabs.history", comment: "History tab")
        static let settings = NSLocalizedString("tabs.settings", comment: "Settings tab")
        static let debug = NSLocalizedString("tabs.debug", comment: "Debug tab")
    }
    enum Login {
        static let title = NSLocalizedString("login.title", comment: "Login title")
        static let identifierPlaceholder = NSLocalizedString("login.identifier_placeholder", comment: "Identifier placeholder")
        static let requestLink = NSLocalizedString("login.request_link", comment: "Request link button")
        static let linkSentHint = NSLocalizedString("login.link_sent_hint", comment: "Hint about checking email/SMS")
        static let linkSentAt = NSLocalizedString("login.link_sent_at", comment: "Link sent at time label")
        static let cooldownMessage = NSLocalizedString("login.cooldown_message", comment: "Cooldown countdown label")
        static let openSupportPage = NSLocalizedString("login.open_support_page", comment: "Button to open account restore/support page")
    }
    enum Subjects {
        static let title = NSLocalizedString("subjects.title", comment: "Subjects title")
        static let emptyState = NSLocalizedString("subjects.empty_state", comment: "Message shown when there are no cues yet")
        static let shuffle = NSLocalizedString("subjects.shuffle", comment: "Shuffle cues button")
    }
    enum Settings {
        static let title = NSLocalizedString("settings.title", comment: "Settings title")
        static let logout = NSLocalizedString("settings.logout", comment: "Logout button")
        static let languagePickerTitle = NSLocalizedString("settings.language_picker_title", comment: "Language picker title")
        static let deleteAccount = NSLocalizedString("settings.delete_account", comment: "Delete account button")
        static let deleteAccountTitle = NSLocalizedString("settings.delete_account_title", comment: "Delete account confirmation title")
        static let deleteAccountMessage = NSLocalizedString("settings.delete_account_message", comment: "Delete account confirmation message")
        static let deleteAccountConfirm = NSLocalizedString("settings.delete_account_confirm", comment: "Delete account confirmation button")
    }
    enum Debug {
        static let networkLogTitle = NSLocalizedString("debug.network_log_title", comment: "Network debug console title")
        static let networkLogDetailTitle = NSLocalizedString("debug.network_log_detail_title", comment: "Network log detail title")
        static let clearLogs = NSLocalizedString("debug.clear_logs", comment: "Clear logs button")
        static let requestSectionTitle = NSLocalizedString("debug.request_section_title", comment: "Request section title")
        static let responseSectionTitle = NSLocalizedString("debug.response_section_title", comment: "Response section title")
        static let methodLabel = NSLocalizedString("debug.method_label", comment: "HTTP method label")
        static let urlLabel = NSLocalizedString("debug.url_label", comment: "URL label")
        static let headersLabel = NSLocalizedString("debug.headers_label", comment: "Headers label")
        static let bodyLabel = NSLocalizedString("debug.body_label", comment: "Body label")
        static let statusLabel = NSLocalizedString("debug.status_label", comment: "Status code label")
        static let errorLabel = NSLocalizedString("debug.error_label", comment: "Error description label")
        static let jsonViewerTitle = NSLocalizedString("debug.json_viewer_title", comment: "JSON viewer title")
        static let requestBodyButton = NSLocalizedString("debug.request_body_button", comment: "Button label to view request JSON body")
        static let responseBodyButton = NSLocalizedString("debug.response_body_button", comment: "Button label to view response JSON body")
        static let rawBodyTitle = NSLocalizedString("debug.raw_body_title", comment: "Title for raw body fallback view")
    }
    enum Errors {
        static let missingIdentifier = NSLocalizedString("errors.missing_identifier", comment: "Missing identifier")
        static let requestFailed = NSLocalizedString("errors.request_failed", comment: "Request failed")
        static let invalidMagicLink = NSLocalizedString("errors.invalid_magic_link", comment: "Invalid magic link")
        static let signInErrorTitle = NSLocalizedString("errors.sign_in_error_title", comment: "Sign-in error title")
        static let settingsLoadTitle = NSLocalizedString("errors.settings_load_title", comment: "Settings load error title")
        static let settingsLoadFailed = NSLocalizedString("errors.settings_load_failed", comment: "Settings load failed")
        static let settingsSaveTitle = NSLocalizedString("errors.settings_save_title", comment: "Settings save error title")
        static let settingsSaveFailed = NSLocalizedString("errors.settings_save_failed", comment: "Settings save failed")
        static let settingsAccountMissing = NSLocalizedString("errors.settings_account_missing", comment: "Settings account missing")
        static let subjectsLoadTitle = NSLocalizedString("errors.subjects_load_title", comment: "Subjects cues load error title")
        static let subjectsLoadFailed = NSLocalizedString("errors.subjects_load_failed", comment: "Subjects cues load failed")
        static let okButton = NSLocalizedString("errors.ok_button", comment: "OK button for error alerts")
        static let deleteAccountTitle = NSLocalizedString("errors.delete_account_title", comment: "Delete account error title")
        static let deleteAccountFailed = NSLocalizedString("errors.delete_account_failed", comment: "Delete account error message")
    }
    enum A11y {
        static let identifierField = NSLocalizedString("a11y.identifier_field", comment: "Identifier field")
        static let errorLabel = NSLocalizedString("a11y.error", comment: "Error label")
        static let logout = NSLocalizedString("a11y.logout", comment: "Logout button")
        static let deleteAccount = NSLocalizedString("a11y.delete_account", comment: "Delete account button")
    }
    enum Common {
        static let ok = NSLocalizedString("common.ok", comment: "OK button")
        static let cancel = NSLocalizedString("common.cancel", comment: "Cancel button")
        static let today = NSLocalizedString("common.today", comment: "Today label")
        static let yesterday = NSLocalizedString("common.yesterday", comment: "Yesterday label")
    }
    enum CueDetail {
        static let title = NSLocalizedString("cue_detail.title", comment: "Cue detail navigation title")
    }
    enum CueHistory {
        static let title = NSLocalizedString("cue_history.title", comment: "Cue recording history navigation title")
        static let emptyState = NSLocalizedString("cue_history.empty_state", comment: "Empty state shown when cue has no recordings")
    }
    enum History {
        static let title = NSLocalizedString("history.title", comment: "Recording History tab title")
        static let emptyState = NSLocalizedString("history.empty_state", comment: "No recordings yet message")
    }
    enum AudioPlayer {
        static let loading = NSLocalizedString("audio_player.loading", comment: "Loading audio")
        static let error = NSLocalizedString("audio_player.error", comment: "Playback error")
    }
    enum Recording {
        static let sectionTitle = NSLocalizedString("recording.section_title", comment: "Recording section title")
        static let startButton = NSLocalizedString("recording.start_button", comment: "Start recording button")
        static let pauseButton = NSLocalizedString("recording.pause_button", comment: "Pause recording button")
        static let resumeButton = NSLocalizedString("recording.resume_button", comment: "Resume recording button")
        static let saveButton = NSLocalizedString("recording.save_button", comment: "Save recording button")
        static let deleteButton = NSLocalizedString("recording.delete_button", comment: "Delete recording button")
        static let deleteConfirmTitle = NSLocalizedString("recording.delete_confirm_title", comment: "Delete confirmation title")
        static let deleteConfirmYes = NSLocalizedString("recording.delete_confirm_yes", comment: "Delete confirmation yes")
        static let deleteConfirmNo = NSLocalizedString("recording.delete_confirm_no", comment: "Delete confirmation no")
        static let successMessage = NSLocalizedString("recording.success_message", comment: "Recording added success message")
        static let permissionDenied = NSLocalizedString("recording.permission_denied", comment: "Microphone permission denied")
        static let uploadError = NSLocalizedString("recording.upload_error", comment: "Upload error message")
        static let historySectionTitle = NSLocalizedString("recording.history_section_title", comment: "Title for recordings list in cue detail view")
        static let newRecordingButton = NSLocalizedString("recording.new_recording_button", comment: "Button label for starting a new recording from history")
        static let viewAll = NSLocalizedString("recording.view_all", comment: "Button label to view all recordings for a cue")
        static func recordingsCount(_ count: Int) -> String {
            String(
                format: NSLocalizedString("recording.recordings_count", comment: "Recordings count label"),
                count
            )
        }
        static let noRecordingFile = NSLocalizedString("recording.no_recording_file", comment: "Error message when no recording file is available")
        static let uploadFailedWithDetail = NSLocalizedString("recording.upload_failed_with_detail", comment: "Upload failed with specific error detail")
    }
    enum Report {
        static let title = NSLocalizedString("report.title", comment: "Report view title")
        static let statusNone = NSLocalizedString("report.status_none", comment: "No report status")
        static let statusProcessing = NSLocalizedString("report.status_processing", comment: "Processing status")
        static let statusReady = NSLocalizedString("report.status_ready", comment: "Ready status")
        static let noReportMessage = NSLocalizedString("report.no_report_message", comment: "No report available message")
        static let requestButton = NSLocalizedString("report.request_button", comment: "Request report button")
        static let processingMessage = NSLocalizedString("report.processing_message", comment: "Processing message")
        static let processingHint = NSLocalizedString("report.processing_hint", comment: "Processing hint")
        static let transcriptTitle = NSLocalizedString("report.transcript_title", comment: "Transcript section title")
        static let buttonLabel = NSLocalizedString("report.button_label", comment: "Report button label")
    }
}


