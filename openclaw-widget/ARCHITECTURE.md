# OpenClaw Widget Architecture (Push-Based)

## Flow

```
┌─────────────────┐     APNs      ┌─────────────────────────┐
│  OpenClaw Agent │ ─────────────▶│  iOS App                │
│  (sends notif)  │               │  - Receives push        │
└─────────────────┘               │  - NSE intercepts       │
                                  │  - Parses sentiment     │
                                  │  - Stores in UserDefaults│
                                  └───────────┬─────────────┘
                                              │
                                              │ App Group
                                              ▼
                                  ┌─────────────────────────┐
                                  │  Widget/Live Activity   │
                                  │  - Reads UserDefaults   │
                                  │  - Updates face         │
                                  │  - Reactive animations  │
                                  └─────────────────────────┘
```

## Components

### 1. OpenClaw Agent (Sender)
Sends push notifications with:
- `state`: idle | thinking | talking | error
- `sentiment`: neutral | positive | negative | urgent
- `message_preview`: truncated text
- `token_usage`: current/limit
- `timestamp`: ISO 8601

### 2. iOS Notification Service Extension (NSE)
- Intercepts incoming notifications
- Parses the payload
- Stores state in Shared UserDefaults
- Triggers widget reload

### 3. Widget/Live Activity
- Reads from UserDefaults on every timeline update
- Maps state to face expressions
- Animates transitions

## Data Flow

```swift
// 1. Agent sends push notification
{
  "aps": {
    "alert": {
      "title": "OpenClaw",
      "body": "Processing your request..."
    },
    "mutable-content": 1,
    "category": "openclaw_state"
  },
  "openclaw": {
    "state": "thinking",
    "sentiment": "neutral",
    "token_usage": {"current": 45000, "limit": 200000},
    "session_age": 120,
    "timestamp": "2026-02-17T03:34:00Z"
  }
}

// 2. NSE processes and stores
UserDefaults(suiteName: "group.com.openclaw.widget")?.set(
  data, forKey: "openclaw_state"
)

// 3. Widget reads and displays
let state = UserDefaults(suiteName: "group.com.openclaw.widget")?.data(forKey: "openclaw_state")
```

## Notification Triggers

| Event | State | Sentiment |
|-------|-------|-----------|
| Agent starts thinking | thinking | neutral |
| Agent responds | talking | positive |
| Error occurs | error | negative |
| Long processing | thinking | urgent |
| Session idle | idle | neutral |

## Key Differences from Polling

| Aspect | Old (Polling) | New (Push) |
|--------|---------------|------------|
| Update trigger | 30s timer | Instant notification |
| Battery impact | Higher (background process) | Lower (push triggered) |
| Latency | 30s delay | Real-time |
| Requires | Running monitor | APNs + NSE |
| Offline handling | Last known state | Cached state |
