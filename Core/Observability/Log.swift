import os

enum Log {
    static let app = Logger(subsystem: "com.chatterboxtalk", category: "app")
    static let network = Logger(subsystem: "com.chatterboxtalk", category: "network")
    static let session = Logger(subsystem: "com.chatterboxtalk", category: "session")
    static let analytics = Logger(subsystem: "com.chatterboxtalk", category: "analytics")
    static let ui = Logger(subsystem: "com.chatterboxtalk", category: "ui")
}


