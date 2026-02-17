# OpenClaw Widget — Project Summary

## 🎯 What You Get

A complete iOS widget system that displays your OpenClaw session status as a reactive BMO-style face.

### Visual States
- **Idle** → Soft blue-gray, calm blinking
- **Thinking** → Warm pink, narrowed eyes, pulsing
- **Talking** → Soft green, wide eyes
- **Error** → Red alert, concerned look
- **Offline** → Dimmed gray, closed eyes

### Widget Sizes
- **Small** → Just the face (pure character)
- **Medium** → Face + token stats
- **Large** → Full dashboard with all metrics

## 📁 Project Structure

```
openclaw-widget/
├── OpenClawWidget/              # Swift source files
│   ├── SessionStatus.swift      # Data models
│   ├── Provider.swift           # WidgetKit timeline provider
│   ├── FaceView.swift           # Animated face component
│   ├── WidgetViews.swift        # Small/Medium/Large layouts
│   └── OpenClawWidget.swift     # Widget configuration
│
├── Scripts/                     # Background tools
│   ├── monitor-session.sh       # Main session monitor
│   ├── write-session-state.js   # Manual state writer
│   └── com.openclaw.widget-session-monitor.plist
│
├── setup.sh                     # One-command setup ⭐
├── verify.sh                    # Verify installation
├── Makefile                     # Convenient commands
└── README.md                    # Full documentation
```

## 🚀 Quick Start

```bash
cd ~/.openclaw/workspace/openclaw-widget
./setup.sh
```

Then open Xcode and create your widget target.

## 🛠️ Available Commands

```bash
make setup      # Full setup
make install    # Install monitor only
make restart    # Restart monitor
make status     # Check status
make logs       # View logs
make test       # Write test state
make clean      # Remove generated files
./verify.sh     # Verify everything is working
```

## 🔌 Data Flow

```
┌─────────────────┐
│  OpenClaw CLI   │
│  (your session) │
└────────┬────────┘
         │
         │ openclaw status
         │ (every 30s)
         ▼
┌─────────────────────────┐
│  monitor-session.sh     │
│  (background service)   │
└────────┬────────────────┘
         │
         │ writes JSON
         ▼
┌─────────────────────────────┐     ┌─────────────────┐
│  ~/.openclaw/widget-        │────▶│  iCloud Drive   │
│  session-state.json         │     │  (optional sync)│
└────────┬────────────────────┘     └─────────────────┘
         │
         │ WidgetKit reads
         ▼
┌─────────────────────────┐
│  iOS Widget             │
│  (reactive face UI)     │
└─────────────────────────┘
```

## 📱 iOS Integration

1. **Create Widget Extension** in Xcode
2. **Configure App Group**: `group.com.openclaw.widget`
3. **Copy Swift files** from `OpenClawWidget/`
4. **Build** → Widget appears in gallery

The widget automatically:
- Reads state from the shared JSON file
- Updates on a dynamic timeline (30s-5min based on activity)
- Animates the face based on session state
- Shows token usage in corner indicators

## ⚙️ Customization

### Change Update Frequency
Edit `Scripts/monitor-session.sh`:
```bash
sleep 30  # Change this value (in seconds)
```

### Add New States
1. Add to `SessionStatus.SessionState` enum
2. Add color in `FaceView.backgroundColor`
3. Add eye behavior in `EyeView.eyeHeight`

### Custom Colors
Edit `FaceView.swift`:
```swift
private var backgroundColor: Color {
    switch state {
    case .idle: return Color(hex: "your-color")
    // ...
    }
}
```

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Widget shows placeholder | Check monitor is running: `make status` |
| State not updating | Check logs: `make logs` |
| Monitor won't start | Run `chmod +x Scripts/*.sh` |
| Widget not appearing | Verify App Group is configured |

## ✅ Completion Checklist

- [x] Swift widget source code
- [x] Session state monitor (bash)
- [x] Manual state writer (Node.js)
- [x] macOS LaunchAgent setup
- [x] iCloud Drive sync support
- [x] Setup script
- [x] Verification script
- [x] Comprehensive documentation
- [x] Makefile for convenience

## 📝 Notes

- The monitor runs as a background service (no terminal window needed)
- State updates every 30 seconds when active, less frequently when idle
- Widget refreshes are handled by WidgetKit's timeline system
- Works with or without iCloud Drive

---

**Ready to use!** Run `./setup.sh` to begin.
