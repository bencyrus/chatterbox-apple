import os

enum Log {
    static let app = Logger(subsystem: "com.chatterbox.ios", category: "app")
    static let network = Logger(subsystem: "com.chatterbox.ios", category: "network")
    static let session = Logger(subsystem: "com.chatterbox.ios", category: "session")
    static let analytics = Logger(subsystem: "com.chatterbox.ios", category: "analytics")
    static let ui = Logger(subsystem: "com.chatterbox.ios", category: "ui")
}


