import Foundation

@Observable
@MainActor
final class HistoryViewModel {
    private let recordingRepository: RecordingRepository
    private let activeProfileHelper: ActiveProfileHelper
    
    struct GroupedRecordings: Identifiable {
        let date: Date
        let recordings: [Recording]
        
        var id: String {
            // Use a simple date formatter to ensure unique IDs based on the date
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }
    }
    
    private(set) var groupedRecordings: [GroupedRecordings] = []
    private(set) var processedFiles: [ProcessedFile] = []
    private(set) var isLoading: Bool = false
    
    var errorAlertTitle: String = ""
    var errorAlertMessage: String = ""
    var isShowingErrorAlert: Bool = false
    
    init(recordingRepository: RecordingRepository, activeProfileHelper: ActiveProfileHelper) {
        self.recordingRepository = recordingRepository
        self.activeProfileHelper = activeProfileHelper
    }
    
    func loadRecordingHistory() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let profile = try await activeProfileHelper.ensureActiveProfile()
            let response = try await recordingRepository.fetchProfileRecordingHistory(profileId: profile.profileId)
            
            processedFiles = response.processedFiles ?? []
            groupedRecordings = groupRecordingsByDate(response.recordings)
        } catch {
            showError(title: Strings.Errors.subjectsLoadTitle, message: Strings.Errors.subjectsLoadFailed)
        }
    }
    
    func reloadForActiveProfileChange() async {
        activeProfileHelper.clearCache()
        await loadRecordingHistory()
    }
    
    func requestTranscription(for profileCueRecordingId: Int64) async {
        do {
            _ = try await recordingRepository.requestTranscription(profileCueRecordingId: profileCueRecordingId)
            // Reload to get updated status
            await loadRecordingHistory()
        } catch {
            showError(title: Strings.Errors.subjectsLoadTitle, message: Strings.Errors.subjectsLoadFailed)
        }
    }
    
    func findRecording(by profileCueRecordingId: Int64) -> Recording? {
        for group in groupedRecordings {
            if let recording = group.recordings.first(where: { $0.profileCueRecordingId == profileCueRecordingId }) {
                return recording
            }
        }
        return nil
    }
    
    private func groupRecordingsByDate(_ recordings: [Recording]) -> [GroupedRecordings] {
        let calendar = Calendar.current
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Group recordings by date string (yyyy-MM-dd) to avoid Date comparison issues
        let grouped = Dictionary(grouping: recordings) { recording -> String in
            // Parse ISO 8601 date string
            guard let date = formatter.date(from: recording.createdAt) else {
                return "unknown"
            }
            // Get the date string (yyyy-MM-dd)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return dateFormatter.string(from: date)
        }
        
        // Convert to array, sort recordings within each group, and sort groups by date
        return grouped.compactMap { (dateString, recordings) -> GroupedRecordings? in
            // Get the actual Date from the first recording in the group
            guard let firstRecording = recordings.first,
                  let date = formatter.date(from: firstRecording.createdAt) else {
                return nil
            }
            let startOfDay = calendar.startOfDay(for: date)
            
            // Sort recordings within the group by creation time (most recent first)
            let sortedRecordings = recordings.sorted { recording1, recording2 in
                guard let date1 = formatter.date(from: recording1.createdAt),
                      let date2 = formatter.date(from: recording2.createdAt) else {
                    return false
                }
                return date1 > date2
            }
            return GroupedRecordings(date: startOfDay, recordings: sortedRecordings)
        }
        .sorted { $0.date > $1.date }
    }
    
    private func showError(title: String, message: String) {
        errorAlertTitle = title
        errorAlertMessage = message
        isShowingErrorAlert = true
    }
}


