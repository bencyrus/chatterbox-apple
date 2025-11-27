import XCTest
@testable import Chatterbox

final class SessionControllerTests: XCTestCase {
    func testInitialStateIsSignedOut() async {
        let controller = SessionController()
        let state = await controller.currentState
        XCTAssertEqual(state, .signedOut)
        let token = await controller.currentAccessToken
        XCTAssertNil(token)
    }

    func testLoginSucceededUpdatesStateAndToken() async {
        let controller = SessionController()
        let tokens = AuthTokens(accessToken: "access", refreshToken: "refresh")

        await controller.loginSucceeded(with: tokens)

        let state = await controller.currentState
        let accessToken = await controller.currentAccessToken

        XCTAssertEqual(state, .authenticated)
        XCTAssertEqual(accessToken, "access")
    }

    func testLogoutClearsTokensAndSetsSignedOut() async {
        let controller = SessionController()
        let tokens = AuthTokens(accessToken: "access", refreshToken: "refresh")

        await controller.loginSucceeded(with: tokens)
        await controller.logout()

        let state = await controller.currentState
        let accessToken = await controller.currentAccessToken

        XCTAssertEqual(state, .signedOut)
        XCTAssertNil(accessToken)
    }
}


