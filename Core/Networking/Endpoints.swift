import Foundation

// MARK: - Common

struct NoResponseBody: Decodable {}

// MARK: - Auth

enum AuthEndpoints {
    struct RequestMagicLink: APIEndpoint {
        typealias RequestBody = RequestMagicLinkBody
        typealias ResponseBody = NoResponseBody

        let path: String = "/rpc/request_magic_link"
        let method: HTTPMethod = .post
        let requiresAuth: Bool = false
        let timeout: TimeInterval = 30
        let idempotencyKeyStrategy: IdempotencyKeyStrategy = .none
    }

    struct LoginWithMagicToken: APIEndpoint {
        struct Body: Encodable {
            let token: String
        }

        typealias RequestBody = Body
        typealias ResponseBody = LoginWithMagicTokenResponse

        let path: String = "/rpc/login_with_magic_token"
        let method: HTTPMethod = .post
        let requiresAuth: Bool = false
        let timeout: TimeInterval = 30
        let idempotencyKeyStrategy: IdempotencyKeyStrategy = .none
    }
}

// MARK: - Account / Profile

enum AccountEndpoints {
    struct Me: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = MeResponse

        let path: String = "/rpc/me"
        let method: HTTPMethod = .post
        let requiresAuth: Bool = true
        let timeout: TimeInterval = 30
        let idempotencyKeyStrategy: IdempotencyKeyStrategy = .none
    }

    struct AppConfig: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = AppConfigResponse

        let path: String = "/rpc/app_config"
        let method: HTTPMethod = .post
        let requiresAuth: Bool = true
        let timeout: TimeInterval = 30
        let idempotencyKeyStrategy: IdempotencyKeyStrategy = .none
    }

    struct SetActiveProfile: APIEndpoint {
        struct Body: Encodable {
            let accountId: Int64
            let languageCode: String
        }

        typealias RequestBody = Body
        typealias ResponseBody = NoResponseBody

        let path: String = "/rpc/set_active_profile"
        let method: HTTPMethod = .post
        let requiresAuth: Bool = true
        let timeout: TimeInterval = 30
        let idempotencyKeyStrategy: IdempotencyKeyStrategy = .none
    }
}

// MARK: - Cues

enum CueEndpoints {
    struct GetCues: APIEndpoint {
        struct Body: Encodable {
            let profileId: Int64
            let count: Int
        }

        typealias RequestBody = Body
        typealias ResponseBody = [Cue]

        let path: String = "/rpc/get_cues"
        let method: HTTPMethod = .post
        let requiresAuth: Bool = true
        let timeout: TimeInterval = 30
        let idempotencyKeyStrategy: IdempotencyKeyStrategy = .none
    }

    struct ShuffleCues: APIEndpoint {
        struct Body: Encodable {
            let profileId: Int64
            let count: Int
        }

        typealias RequestBody = Body
        typealias ResponseBody = [Cue]

        let path: String = "/rpc/shuffle_cues"
        let method: HTTPMethod = .post
        let requiresAuth: Bool = true
        let timeout: TimeInterval = 30
        let idempotencyKeyStrategy: IdempotencyKeyStrategy = .none
    }
}


