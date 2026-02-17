import WidgetKit
import SwiftUI

struct OpenClawWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            FaceView(state: entry.state, tokenPercentage: entry.tokenUsage.percentage)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            FaceView(state: entry.state, tokenPercentage: entry.tokenUsage.percentage)
        }
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        HStack(spacing: 16) {
            // Left: The face
            FaceView(state: entry.state, tokenPercentage: entry.tokenUsage.percentage)
                .frame(width: 100)
            
            // Right: Stats
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.state.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text("\(entry.tokenUsage.current / 1000)k / \(entry.tokenUsage.limit / 1000)k")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(entry.model)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                Text(formatTime(entry.sessionAge))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Large Widget
struct LargeWidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        VStack(spacing: 0) {
            // Top: Large face
            FaceView(state: entry.state, tokenPercentage: entry.tokenUsage.percentage)
                .frame(height: 180)
            
            // Bottom: Detailed stats
            VStack(spacing: 12) {
                HStack {
                    StatItem(title: "Status", value: entry.state.rawValue.capitalized)
                    Spacer()
                    StatItem(title: "Model", value: entry.model)
                }
                
                Divider()
                
                HStack {
                    StatItem(
                        title: "Tokens",
                        value: "\(entry.tokenUsage.current / 1000)k / \(entry.tokenUsage.limit / 1000)k"
                    )
                    Spacer()
                    StatItem(title: "Session", value: formatTime(entry.sessionAge))
                }
                
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.black.opacity(0.1))
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(tokenColor(for: entry.tokenUsage.percentage))
                            .frame(width: geo.size.width * entry.tokenUsage.percentage, height: 4)
                    }
                }
                .frame(height: 4)
            }
            .padding()
        }
    }
    
    private func tokenColor(for percentage: Double) -> Color {
        switch percentage {
        case 0..<0.5: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }
}

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Helpers
func formatTime(_ interval: TimeInterval) -> String {
    let hours = Int(interval) / 3600
    let minutes = Int(interval) % 3600 / 60
    
    if hours > 0 {
        return "\(hours)h \(minutes)m"
    } else {
        return "\(minutes)m"
    }
}
