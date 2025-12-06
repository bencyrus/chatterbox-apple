import Foundation

struct RequestMagicLinkBody: Encodable {
    let identifier: String
}

struct LoginWithMagicTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
}
