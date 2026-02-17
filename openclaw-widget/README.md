# OpenClaw Session Widget

A reactive, minimalistic iOS widget that displays your OpenClaw session status with a BMO-inspired face.

![Widget Preview](preview.png)

## Features

- **Geometric face** with animated square eyes
- **Dynamic colors** based on session state (idle, thinking, talking, error, offline)
- **3 sizes**: Small (face only), Medium (face + stats), Large (full dashboard)
- **Subtle animations**: Blinking, looking around, pulsing when thinking
- **Token usage indicators** without cluttering the design
- **Auto-syncing** via iCloud Drive or local file

## Quick Start

```bash
cd ~/.openclaw/workspace/openclaw-widget
./setup.sh
```

This will:
1. Install the background session monitor
2. Set up automatic state updates every 30 seconds
3. Create the initial state file

## State Colors

| State | Color | Description |
|-------|-------|-------------|
| Idle | Soft blue-gray | Waiting for input |
| Thinking | Warm pink/salmon | Processing request |
| Talking | Soft green | Responding |
| Error | Alert red | Something went wrong |
| Offline | Dimmed gray | Not connected |

## Eye Behaviors

- **Idle**: Normal size, slow blinks, subtle look shifts
- **Thinking**: Narrowed, pulsing background
- **Talking**: Wide open, active
- **Error**: Slightly concerned (smaller, tilted)
- **Offline**: Closed/dimmed

## Installation

### 1. Run Setup Script
```bash
cd openclaw-widget
./setup.sh
```

### 2. Create Xcode Project
1. Open Xcode
2. Create new iOS App project
3. **File → New → Target → Widget Extension**
4. Name it "OpenClawWidgetExtension"

### 3. Configure App Groups
1. Select the widget target
2. Go to **Signing & Capabilities**
3. Click **+ Capability → App Groups**
4. Add: `group.com.openclaw.widget`

### 4. Copy Widget Files
Copy all files from `OpenClawWidget/` into your widget target.

### 5. Build and Run
The widget will now appear in your widgets gallery!

## Data Flow

```
OpenClaw Session → monitor-session.sh → state file → iOS Widget
                      (every 30s)
```

The monitor reads `openclaw status` and writes to:
- `~/.openclaw/widget-session-state.json` (local)
- `~/Library/Mobile Documents/com~apple~CloudDocs/openclaw-widget-state.json` (iCloud)

## Manual State Updates

You can manually trigger state updates:

```bash
# Set specific state
node Scripts/write-session-state.js --state thinking 45000 kimi-k2-thinking 120

# Parse from openclaw status
openclaw status | node Scripts/write-session-state.js --status /dev/stdin
```

## File Structure

```
openclaw-widget/
├── OpenClawWidget/               # Swift widget source
│   ├── SessionStatus.swift       # Data models
│   ├── Provider.swift            # WidgetKit timeline
│   ├── FaceView.swift            # Animated face
│   ├── WidgetViews.swift         # Small/Medium/Large layouts
│   └── OpenClawWidget.swift      # Widget configuration
├── Scripts/                      # Background tools
│   ├── monitor-session.sh        # Main monitor (runs every 30s)
│   ├── write-session-state.js    # Direct state writer
│   └── com.openclaw.widget-session-monitor.plist  # macOS service
├── setup.sh                      # One-command setup
├── Package.swift                 # Swift Package Manager
└── README.md                     # This file
```

## Troubleshooting

### Widget shows placeholder data
- Check that the monitor is running: `launchctl list | grep openclaw`
- Check the state file exists: `cat ~/.openclaw/widget-session-state.json`
- View logs: `tail -f ~/.openclaw/widget-monitor.log`

### Monitor not starting
- Make sure scripts are executable: `chmod +x Scripts/*.sh`
- Check logs: `cat ~/.openclaw/widget-monitor.error.log`
- Reload manually: `launchctl load ~/Library/LaunchAgents/com.openclaw.widget-session-monitor.plist`

### Widget not updating
- Widgets refresh based on timeline policy (30s-5min depending on state)
- Try removing and re-adding the widget
- Check that App Group is configured correctly

## Architecture

The widget uses WidgetKit's timeline system:
1. **Provider** loads state from shared file
2. **FaceView** renders the animated face with SwiftUI
3. **Timeline** updates based on activity level (faster when active)

State is determined by parsing `openclaw status` output:
- Token usage (e.g., "55k/200k")
- Session age (e.g., "2m ago")
- Active indicators ("thinking", "reasoning")

## Requirements

- iOS 15+
- macOS (for monitor script)
- Xcode 13+
- OpenClaw CLI installed

## License

MIT - Built with 🌿 for the OpenClaw community
