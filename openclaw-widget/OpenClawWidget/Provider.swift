import WidgetKit
import SwiftUI

@available(iOS 14.0, *)
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SessionStatus {
        SessionStatus.placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SessionStatus) -> Void) {
        let status = loadFromUserDefaults()
        completion(status)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SessionStatus>) -> Void) {
        let status = loadFromUserDefaults()
        
        // Check if we need a more urgent update
        let updateInterval: Int
        let lastUpdate = UserDefaults(suiteName: "group.com.openclaw.widget")?.object(forKey: "openclaw_last_update") as? Date
        let timeSinceUpdate = lastUpdate != nil ? Int(Date().timeIntervalSince(lastUpdate!)) : 9999
        
        // If recent update (< 60s), refresh faster
        if timeSinceUpdate < 60 {
            updateInterval = 15
        } else {
            switch status.state {
            case .thinking, .talking:
                updateInterval = 30
            case .idle:
                updateInterval = 120
            case .error:
                updateInterval = 60
            case .offline:
                updateInterval = 300
            }
        }
        
        let nextUpdate = Calendar.current.date(byAdding: .second, value: updateInterval, to: Date())!
        let timeline = Timeline(entries: [status], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    // MARK: - Load from UserDefaults (set by NSE)
    private func loadFromUserDefaults() -> SessionStatus {
        guard let userDefaults = UserDefaults(suiteName: "group.com.openclaw.widget"),
              let stateData = userDefaults.dictionary(forKey: "openclaw_state") else {
            return SessionStatus.placeholder
        }
        
        let stateStr = stateData["state"] as? String ?? "idle"
        let tokenUsage = stateData["token_usage"] as? [String: Int] ?? ["current": 0, "limit": 200000]
        
        return SessionStatus(
            date: Date(),
            state: SessionStatus.SessionState(rawValue: stateStr) ?? .idle,
            tokenUsage: SessionStatus.TokenUsage(
                current: tokenUsage["current"] ?? 0,
                limit: tokenUsage["limit"] ?? 200000
            ),
            model: "kimi-k2-thinking",
            sessionAge: stateData["session_age"] as? TimeInterval ?? 0
        )
    }
}
