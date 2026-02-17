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
        
        // More frequent updates for smoother animations
        let updateInterval: Int
        switch status.state {
        case .thinking, .talking:
            updateInterval = 5  // 5 seconds for active states
        case .idle:
            updateInterval = 30
        case .error:
            updateInterval = 10
        case .offline:
            updateInterval = 60
        }
        
        let nextUpdate = Calendar.current.date(byAdding: .second, value: updateInterval, to: Date())!
        let timeline = Timeline(entries: [status], policy: .after(nextUpdate))
        completion(timeline)
    }
    
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

// MARK: - Widget Entry View
struct OpenClawWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated SpriteKit face
                AnimatedFaceView(
                    state: entry.state,
                    tokenPercentage: entry.tokenUsage.percentage
                )
                
                // Overlay info for larger sizes
                if family != .systemSmall {
                    VStack {
                        Spacer()
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.state.rawValue.uppercased())
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black.opacity(0.6))
                                
                                Text("\(Int(entry.tokenUsage.percentage * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.black.opacity(0.5))
                            }
                            .padding(8)
                            .background(.white.opacity(0.3))
                            .cornerRadius(8)
                            
                            Spacer()
                        }
                        .padding(12)
                    }
                }
            }
        }
    }
}

// MARK: - Widget Configuration
@main
struct OpenClawWidgetBundle: WidgetBundle {
    var body: some Widget {
        OpenClawWidget()
    }
}

struct OpenClawWidget: Widget {
    let kind: String = "OpenClawWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            OpenClawWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("OpenClaw Session")
        .description("Real-time animated session status")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
