import Foundation

struct RequestCodeBody: Encodable {
    let identifier: String
}

struct VerifyCodeBody: Encodable {
    let identifier: String
    let code: String
}

struct VerifyResponse: Decodable {
    let access_token: String
    let refresh_token: String
}


