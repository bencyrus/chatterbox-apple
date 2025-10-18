import Foundation

struct RequestMagicLinkBody: Encodable {
    let identifier: String
}

struct LoginWithMagicTokenResponse: Decodable {
    let access_token: String
    let refresh_token: String
}


