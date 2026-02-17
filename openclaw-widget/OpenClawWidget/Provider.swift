import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SessionStatus {
        SessionStatus.placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SessionStatus) -> Void) {
        let status = loadFromSharedContainer()
        completion(status)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SessionStatus>) -> Void) {
        let status = loadFromSharedContainer()
        
        // Update more frequently when active/thinking
        let updateInterval: Int
        switch status.state {
        case .thinking, .talking:
            updateInterval = 30  // 30 seconds
        case .idle:
            updateInterval = 120 // 2 minutes
        case .error:
            updateInterval = 60  // 1 minute
        case .offline:
            updateInterval = 300 // 5 minutes
        }
        
        let nextUpdate = Calendar.current.date(byAdding: .second, value: updateInterval, to: Date())!
        let timeline = Timeline(entries: [status], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    // MARK: - Production Data Loading
    private func loadFromSharedContainer() -> SessionStatus {
        // Try multiple locations for the state file
        let possiblePaths = [
            // iCloud Drive (preferred - syncs across devices)
            FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                .appendingPathComponent("../Mobile Documents/com~apple~CloudDocs/openclaw-widget-state.json"),
            // Local fallback
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".openclaw/widget-session-state.json"),
            // App Group (if configured)
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.openclaw.widget")?
                .appendingPathComponent("session-state.json")
        ].compactMap { $0 }
        
        for path in possiblePaths {
            if let data = try? Data(contentsOf: path),
               let status = try? JSONDecoder().decode(SessionStatus.self, from: data) {
                return status
            }
        }
        
        // Return placeholder if no state file found
        return SessionStatus.placeholder
    }
}
