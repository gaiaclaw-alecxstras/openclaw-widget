import UserNotifications
import WidgetKit

class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        self.bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        guard let bestAttemptContent = bestAttemptContent else {
            contentHandler(request.content)
            return
        }
        
        // Parse OpenClaw state from notification
        if let openclawData = request.content.userInfo["openclaw"] as? [String: Any] {
            storeState(openclawData)
            
            // Update widget
            WidgetCenter.shared.reloadTimelines(ofKind: "OpenClawWidget")
            
            // Analyze sentiment for display
            let sentiment = analyzeSentiment(openclawData)
            bestAttemptContent.body = formatDisplayText(openclawData, sentiment: sentiment)
        }
        
        contentHandler(bestAttemptContent)
    }
    
    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    // MARK: - State Management
    
    private func storeState(_ data: [String: Any]) {
        guard let userDefaults = UserDefaults(suiteName: "group.com.openclaw.widget") else {
            return
        }
        
        let state: [String: Any] = [
            "state": data["state"] as? String ?? "idle",
            "sentiment": data["sentiment"] as? String ?? "neutral",
            "token_usage": data["token_usage"] as? [String: Int] ?? ["current": 0, "limit": 200000],
            "session_age": data["session_age"] as? Int ?? 0,
            "timestamp": data["timestamp"] as? String ?? ISO8601DateFormatter().string(from: Date())
        ]
        
        userDefaults.set(state, forKey: "openclaw_state")
        userDefaults.set(Date(), forKey: "openclaw_last_update")
    }
    
    // MARK: - Sentiment Analysis
    
    private func analyzeSentiment(_ data: [String: Any]) -> String {
        let state = data["state"] as? String ?? "idle"
        
        switch state {
        case "thinking":
            return "neutral"
        case "talking":
            return "positive"
        case "error":
            return "negative"
        case "idle":
            return "neutral"
        default:
            return "neutral"
        }
    }
    
    private func formatDisplayText(_ data: [String: Any], sentiment: String) -> String {
        let state = data["state"] as? String ?? "idle"
        
        switch state {
        case "thinking":
            return "🤔 Thinking..."
        case "talking":
            return "💬 Responding"
        case "error":
            return "❌ Error occurred"
        case "idle":
            return "😴 Idle"
        default:
            return "OpenClaw Active"
        }
    }
}
