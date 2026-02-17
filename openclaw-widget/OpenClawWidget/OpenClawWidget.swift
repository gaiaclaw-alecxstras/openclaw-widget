import WidgetKit
import SwiftUI

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
        .description("Monitor your OpenClaw session status at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
