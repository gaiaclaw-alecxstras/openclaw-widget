#!/bin/bash
#
# Setup script for OpenClaw Widget
# Run this to install the session monitor and configure your system
#

set -e

echo "🌿 OpenClaw Widget Setup"
echo "========================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"

# Step 1: Create necessary directories
echo -e "${YELLOW}Step 1: Creating directories...${NC}"
mkdir -p ~/.openclaw
mkdir -p ~/Library/Mobile\ Documents/com~apple~CloudDocs 2>/dev/null || true
echo -e "${GREEN}✓ Directories created${NC}"

# Step 2: Make scripts executable
echo -e "${YELLOW}Step 2: Setting up scripts...${NC}"
chmod +x "$SCRIPT_DIR/Scripts/monitor-session.sh"
chmod +x "$SCRIPT_DIR/Scripts/write-session-state.js"
echo -e "${GREEN}✓ Scripts ready${NC}"

# Step 3: Install LaunchAgent (macOS background service)
echo -e "${YELLOW}Step 3: Installing background monitor...${NC}"
LAUNCHAGENTS_DIR="$HOME/Library/LaunchAgents"
mkdir -p "$LAUNCHAGENTS_DIR"

# Replace ~ with actual home directory in plist
sed "s|~|$HOME|g" "$SCRIPT_DIR/Scripts/com.openclaw.widget-session-monitor.plist" > "$LAUNCHAGENTS_DIR/com.openclaw.widget-session-monitor.plist"

# Load the agent
launchctl unload "$LAUNCHAGENTS_DIR/com.openclaw.widget-session-monitor.plist" 2>/dev/null || true
launchctl load "$LAUNCHAGENTS_DIR/com.openclaw.widget-session-monitor.plist"

echo -e "${GREEN}✓ Background monitor installed${NC}"
echo "  Logs: ~/.openclaw/widget-monitor.log"

# Step 4: Create initial state file
echo -e "${YELLOW}Step 4: Creating initial state...${NC}"
cat > ~/.openclaw/widget-session-state.json <<EOF
{
  "date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "state": "idle",
  "tokenUsage": {
    "current": 0,
    "limit": 200000
  },
  "model": "unknown",
  "sessionAge": 0
}
EOF
echo -e "${GREEN}✓ Initial state created${NC}"

# Step 5: Test the monitor
echo -e "${YELLOW}Step 5: Testing monitor...${NC}"
sleep 2
if [ -f ~/.openclaw/widget-session-state.json ]; then
    echo -e "${GREEN}✓ State file is being updated${NC}"
    echo "  Current state:"
    cat ~/.openclaw/widget-session-state.json | head -6
else
    echo -e "${RED}✗ State file not found - check logs${NC}"
fi

echo ""
echo "========================"
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Open Xcode and create a new iOS App project"
echo "2. Add a Widget Extension target (File → New → Target → Widget Extension)"
echo "3. Copy the files from: $WORKSPACE_DIR/OpenClawWidget/"
echo "4. Set your App Group to: group.com.openclaw.widget"
echo "5. Build and run!"
echo ""
echo "To check monitor status: launchctl list | grep openclaw"
echo "To view logs: tail -f ~/.openclaw/widget-monitor.log"
echo "To stop monitor: launchctl unload ~/Library/LaunchAgents/com.openclaw.widget-session-monitor.plist"
