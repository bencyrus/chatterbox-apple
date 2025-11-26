import XCTest
@testable import Chatterbox

final class HomeViewModelTests: XCTestCase {
    private final class FakeAccountRepository: AccountRepository {
        var me: MeResponse
        var config: AppConfigResponse

        init(me: MeResponse, config: AppConfigResponse) {
            self.me = me
            self.config = config
        }

        func fetchMe() async throws -> MeResponse {
            me
        }

        func fetchAppConfig() async throws -> AppConfigResponse {
            config
        }

        func setActiveProfile(accountId: Int64, languageCode: String) async throws {
            let active = ActiveProfileSummary(
                accountId: accountId,
                profileId: 1,
                languageCode: languageCode
            )
            me = MeResponse(account: me.account, activeProfile: active)
        }
    }

    private final class FakeCueRepository: CueRepository {
        var cuesToReturn: [Cue] = []

        func fetchCues(profileId: Int64, count: Int) async throws -> [Cue] {
            cuesToReturn
        }

        func shuffleCues(profileId: Int64, count: Int) async throws -> [Cue] {
            cuesToReturn
        }
    }

    func testLoadInitialCues_usesExistingActiveProfile() async throws {
        let account = AccountSummary(accountId: 1, email: "test@example.com", phoneNumber: nil)
        let envelope = AccountEnvelope(account: account, accountRole: "user", lastLoginAt: nil)
        let active = ActiveProfileSummary(accountId: 1, profileId: 10, languageCode: "en")
        let me = MeResponse(account: envelope, activeProfile: active)
        let config = AppConfigResponse(defaultProfileLanguageCode: "en", availableLanguageCodes: ["en"])

        let accountRepo = FakeAccountRepository(me: me, config: config)
        let cueRepo = FakeCueRepository()

        let content = CueContent(
            cueContentId: 1,
            cueId: 1,
            title: "Title",
            details: "Details",
            languageCode: "en",
            createdAt: "2024-01-01T00:00:00Z"
        )
        let cue = Cue(
            cueId: 1,
            stage: "published",
            createdAt: "2024-01-01T00:00:00Z",
            createdBy: 1,
            content: content
        )
        cueRepo.cuesToReturn = [cue]

        let helper = ActiveProfileHelper(accountRepository: accountRepo)
        let viewModel = HomeViewModel(activeProfileHelper: helper, cueRepository: cueRepo)

        await viewModel.loadInitialCues()

        XCTAssertEqual(viewModel.cues.count, 1)
        XCTAssertEqual(viewModel.cues.first?.content.title, "Title")
    }
}


