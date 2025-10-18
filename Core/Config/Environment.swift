import Foundation
import Observation

@Observable
final class AppEnvironment {
    // Base URL for the gateway (PostgREST sits behind it)
    var baseURL: URL

    // RPC paths
    let requestMagicLinkPath: String = "/rpc/request_magic_link"
    let loginWithMagicTokenPath: String = "/rpc/login_with_magic_token"

    // Gateway token refresh headers (outgoing from gateway to client)
    let newAccessTokenHeaderOut: String = "X-New-Access-Token"
    let newRefreshTokenHeaderOut: String = "X-New-Refresh-Token"

    init(baseURL: URL = URL(string: "https://api.glovee.io")!) {
        self.baseURL = baseURL
    }
}


