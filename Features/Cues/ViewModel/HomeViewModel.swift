import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    private let activeProfileHelper: ActiveProfileHelper
    private let cueRepository: CueRepository
    private let configProvider: ConfigProviding

    // MARK: - State

    private(set) var cues: [Cue] = []

    var isLoading: Bool = false

    var errorAlertTitle: String = ""
    var errorAlertMessage: String = ""
    var isShowingErrorAlert: Bool = false

    init(
        activeProfileHelper: ActiveProfileHelper,
        cueRepository: CueRepository,
        configProvider: ConfigProviding
    ) {
        self.activeProfileHelper = activeProfileHelper
        self.cueRepository = cueRepository
        self.configProvider = configProvider
    }

    // MARK: - Intents

    func loadInitialCues() async {
        // Avoid re-fetching cues on every view appearance. If we already have
        // a non-empty list, we keep showing it until the user explicitly
        // refreshes (e.g., shuffle) or the active profile changes.
        if !cues.isEmpty {
            return
        }
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
        activeProfileHelper.clearCache()
        cues = []
        await loadCues(useShuffle: false, showErrors: false)
    }

    // MARK: - Internal

    private func loadCues(useShuffle: Bool, showErrors: Bool) async {
        if isLoading { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let profile = try await resolveActiveProfile()
            let count = configProvider.snapshot.cuesPageSize

            // Let the backend control ordering, shuffling, and any duplicates.
            // The app simply renders whatever list of cues it receives.
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

            cues = loadedCues
        } catch {
            // Ignore benign cancellation errors caused by overlapping requests when
            // navigation or profile changes trigger a new load and cancel the old one.
            if let urlError = error as? URLError, urlError.code == .cancelled {
                return
            }
            // When the backend reports unauthorized, the API client will already
            // have triggered a logout via SessionController. In that case we avoid
            // showing a "could not load cards" error and let the app transition
            // back to the sign-in flow instead.
            if case NetworkError.unauthorized = error {
                return
            }
            // Only show the error if we don't currently have any cues to show.
            // This avoids flashing an error when a background refresh fails
            // but the user still has a valid set of cards on screen.
            if showErrors && cues.isEmpty {
                presentError(
                    title: Strings.Errors.subjectsLoadTitle,
                    message: Strings.Errors.subjectsLoadFailed
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


