#!/bin/bash
#
# OpenClaw Session State Monitor
# 
# Runs in background and periodically updates the widget session state.
# Add to crontab or run as a LaunchAgent on macOS.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_FILE="${HOME}/.openclaw/widget-session-state.json"
PIDFILE="${HOME}/.openclaw/widget-monitor.pid"

# Ensure directory exists
mkdir -p "$(dirname "$STATE_FILE")"

# Cleanup on exit
cleanup() {
    rm -f "$PIDFILE"
    exit 0
}
trap cleanup SIGINT SIGTERM

# Write PID
echo $$ > "$PIDFILE"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

get_session_state() {
    local output
    output=$(openclaw status 2>/dev/null || echo "")
    
    if [ -z "$output" ]; then
        echo '{"state":"offline","tokenUsage":{"current":0,"limit":200000},"model":"unknown","sessionAge":0}'
        return
    fi
    
    # Parse tokens (55k/200k format)
    local tokens=$(echo "$output" | grep -oE '[0-9]+k/[0-9]+k' | head -1)
    local current=$(echo "$tokens" | cut -d'/' -f1 | sed 's/k//')
    local limit=$(echo "$tokens" | cut -d'/' -f2 | sed 's/k//')
    
    # Parse age
    local age_str=$(echo "$output" | grep -oE '[0-9]+(m|h)\s+ago' | head -1)
    local age_num=$(echo "$age_str" | grep -oE '[0-9]+')
    local age_unit=$(echo "$age_str" | grep -oE '[mh]')
    local age_seconds=0
    
    if [ "$age_unit" = "h" ]; then
        age_seconds=$((age_num * 3600))
    else
        age_seconds=$((age_num * 60))
    fi
    
    # Parse model
    local model=$(echo "$output" | grep -oE 'kimi-[a-z0-9-]+' | head -1)
    [ -z "$model" ] && model="unknown"
    
    # Determine state
    local state="idle"
    if echo "$output" | grep -q "thinking\|reasoning"; then
        state="thinking"
    elif [ "$age_seconds" -lt 60 ]; then
        state="talking"
    fi
    
    # Build JSON
    cat <<EOF
{
  "date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "state": "$state",
  "tokenUsage": {
    "current": $((current * 1000)),
    "limit": $((limit * 1000))
  },
  "model": "$model",
  "sessionAge": $age_seconds
}
EOF
}

log "Starting OpenClaw Widget Session Monitor..."

# Main loop
while true; do
    state=$(get_session_state)
    echo "$state" > "$STATE_FILE"
    
    # Also update iCloud if available (for widget sync)
    if [ -d "$HOME/Library/Mobile Documents/com~apple~CloudDocs" ]; then
        echo "$state" > "$HOME/Library/Mobile Documents/com~apple~CloudDocs/openclaw-widget-state.json" 2>/dev/null || true
    fi
    
    # Update every 30 seconds
    sleep 30
done
