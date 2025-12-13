import XCTest
@testable import Chatterbox

final class AuthRepositoryTests: XCTestCase {
    var repository: PostgrestAuthRepository!
    var mockSession: URLSession!
    
    override func setUp() {
        super.setUp()
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: config)
    }
    
    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        mockSession = nil
        repository = nil
        super.tearDown()
    }
    
    func testRequestMagicLinkSuccess() async throws {
        // Given: Valid email/phone
        let mockResponse = MagicLinkResponse(cooldownSeconds: 60)
        let jsonData = try JSONEncoder().encode(mockResponse)
        
        MockURLProtocol.requestHandler = { request in
            let url = request.url!
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertTrue(url.absoluteString.contains("/magic-link"))
            
            // Verify request body contains identifier
            if let bodyData = request.httpBody {
                let bodyJSON = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
                XCTAssertNotNil(bodyJSON?["identifier"])
            }
            
            return MockURLProtocol.mockSuccess(statusCode: 200, data: jsonData, url: url)
        }
        
        // When/Then: Test magic link request
        // Template - requires repository with mock session
    }
    
    func testRequestMagicLinkCooldown() async throws {
        // Given: Cooldown error response
        let errorData = """
        {"code": "RATE_LIMIT", "message": "Please wait before requesting another code"}
        """.data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            return MockURLProtocol.mockError(
                statusCode: 429,
                url: request.url!,
                errorData: errorData
            )
        }
        
        // When/Then: Verify cooldown error handling
        // Template
    }
    
    func testLoginWithMagicTokenSuccess() async throws {
        // Given: Valid token
        let mockResponse = LoginResponse(
            accessToken: "mock-access-token",
            refreshToken: "mock-refresh-token",
            expiresIn: 3600
        )
        let jsonData = try JSONEncoder().encode(mockResponse)
        
        MockURLProtocol.requestHandler = { request in
            let url = request.url!
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertTrue(url.absoluteString.contains("/login"))
            
            return MockURLProtocol.mockSuccess(statusCode: 200, data: jsonData, url: url)
        }
        
        // When/Then: Test login
        // Template
    }
    
    func testLoginWithInvalidToken() async throws {
        // Given: Invalid token response
        let errorData = """
        {"code": "INVALID_TOKEN", "message": "Token expired or invalid"}
        """.data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            return MockURLProtocol.mockError(
                statusCode: 401,
                url: request.url!,
                errorData: errorData
            )
        }
        
        // When/Then: Verify error handling
        // Template
    }
}

