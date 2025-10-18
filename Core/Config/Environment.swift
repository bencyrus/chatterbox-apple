import Foundation
import Observation

@Observable
final class AppEnvironment {
    // Base URL for the gateway (PostgREST sits behind it)
    var baseURL: URL

    // RPC paths
    let requestLoginCodePath: String = "/rpc/request_login_code"
    let loginWithCodePath: String = "/rpc/login_with_code"

    // Gateway token refresh headers (outgoing from gateway to client)
    let newAccessTokenHeaderOut: String = "X-New-Access-Token"
    let newRefreshTokenHeaderOut: String = "X-New-Refresh-Token"

    init(baseURL: URL = URL(string: "https://api.glovee.io")!) {
        self.baseURL = baseURL
    }
}


