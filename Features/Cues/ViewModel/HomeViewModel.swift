import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    private let activeProfileHelper: ActiveProfileHelper
    private let cueRepository: CueRepository

    // MARK: - State

    private(set) var cues: [Cue] = []

    var isLoading: Bool = false

    var errorAlertTitle: String = ""
    var errorAlertMessage: String = ""
    var isShowingErrorAlert: Bool = false

    init(
        activeProfileHelper: ActiveProfileHelper,
        cueRepository: CueRepository
    ) {
        self.activeProfileHelper = activeProfileHelper
        self.cueRepository = cueRepository
    }

    // MARK: - Intents

    func loadInitialCues() async {
        await loadCues(useShuffle: false, showErrors: true)
    }

    func shuffleCues() async {
        await loadCues(useShuffle: true, showErrors: true)
    }

    // MARK: - Internal

    func reloadForActiveProfileChange() async {
        // Silent reload used when the active profile changes (e.g., language switch).
        // We don't want to flash an error popup in this case; we just update cards
        // or show the empty state if nothing is available.
        await loadCues(useShuffle: false, showErrors: false)
    }

    // MARK: - Internal

    private func loadCues(useShuffle: Bool, showErrors: Bool) async {
        if isLoading { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let profile = try await resolveActiveProfile()
            let count = 5

            let loadedCues: [Cue]
            if useShuffle {
                loadedCues = try await cueRepository.shuffleCues(
                    profileId: profile.profileId,
                    count: count
                )
            } else {
                loadedCues = try await cueRepository.fetchCues(
                    profileId: profile.profileId,
                    count: count
                )
            }

            // Deduplicate by cueContentId to avoid duplicate IDs in the list
            var seenContentIds = Set<Int64>()
            let uniqueCues = loadedCues.filter { cue in
                let id = cue.content.cueContentId
                if seenContentIds.contains(id) { return false }
                seenContentIds.insert(id)
                return true
            }

            cues = uniqueCues
        } catch {
            // Ignore benign cancellation errors caused by overlapping requests when
            // navigation or profile changes trigger a new load and cancel the old one.
            if let urlError = error as? URLError, urlError.code == .cancelled {
                return
            }
            // Only show the error if we don't currently have any cues to show.
            // This avoids flashing an error when a background refresh fails
            // but the user still has a valid set of cards on screen.
            if showErrors && cues.isEmpty {
                presentError(
                    title: Strings.Errors.homeLoadTitle,
                    message: Strings.Errors.homeLoadFailed
                )
            }
        }
    }

    private func resolveActiveProfile() async throws -> ActiveProfileSummary {
        try await activeProfileHelper.ensureActiveProfile()
    }

    private func presentError(title: String, message: String) {
        errorAlertTitle = title
        errorAlertMessage = message
        isShowingErrorAlert = true
    }
}


