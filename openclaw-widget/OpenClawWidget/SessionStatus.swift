import WidgetKit
import SwiftUI

struct SessionStatus: TimelineEntry, Codable {
    var date: Date = Date()
    let date: Date
    let state: SessionState
    let tokenUsage: TokenUsage
    let model: String
    let sessionAge: TimeInterval
    
    enum SessionState: String, Codable {
        case idle
        case thinking
        case talking
        case error
        case offline
    }
    
    struct TokenUsage: Codable {
        let current: Int
        let limit: Int
        
        var percentage: Double {
            Double(current) / Double(limit)
        }
    }
}

// MARK: - Default/Placeholder Data
extension SessionStatus {
    static let placeholder = SessionStatus(
        date: Date(),
        state: .thinking,
        tokenUsage: TokenUsage(current: 45000, limit: 200000),
        model: "kimi-k2-thinking",
        sessionAge: 120
    )
    
    static let idle = SessionStatus(
        date: Date(),
        state: .idle,
        tokenUsage: TokenUsage(current: 12000, limit: 200000),
        model: "kimi-k2-thinking",
        sessionAge: 1800
    )
}
