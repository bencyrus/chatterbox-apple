import Foundation
import os

struct AnalyticsEvent: Equatable {
    let name: String
    let properties: [String: String]
    let context: [String: String]
    let timestamp: Date
}

protocol AnalyticsSink {
    func record(_ event: AnalyticsEvent) async
}

protocol AnalyticsRecording {
    func record(_ event: AnalyticsEvent)
}

final class AnalyticsRecorder: AnalyticsRecording {
    private let sinks: [AnalyticsSink]

    init(sinks: [AnalyticsSink]) {
        self.sinks = sinks
    }

    func record(_ event: AnalyticsEvent) {
        guard !sinks.isEmpty else { return }
        for sink in sinks {
            Task {
                await sink.record(event)
            }
        }
    }
}

struct OSLogAnalyticsSink: AnalyticsSink {
    func record(_ event: AnalyticsEvent) async {
        // Only log event name and keys to avoid leaking values.
        let keys = event.properties.keys.sorted().joined(separator: ",")
        Log.analytics.info("Analytics event \(event.name) props=\(keys)")
    }
}


