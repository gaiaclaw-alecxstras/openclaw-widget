#!/bin/bash
#
# Verify the OpenClaw Widget setup
#

echo "🔍 OpenClaw Widget Setup Verification"
echo "======================================"
echo ""

ERRORS=0

# Check 1: OpenClaw CLI
echo "Checking OpenClaw CLI..."
if command -v openclaw >/dev/null 2>&1; then
    echo "  ✓ openclaw found"
    openclaw --version 2>/dev/null | head -1 | sed 's/^/    /'
else
    echo "  ✗ openclaw not found in PATH"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 2: State file
echo "Checking state file..."
if [ -f ~/.openclaw/widget-session-state.json ]; then
    echo "  ✓ State file exists"
    echo "  Current state:"
    cat ~/.openclaw/widget-session-state.json | sed 's/^/    /'
else
    echo "  ✗ State file not found"
    echo "  Run: ./setup.sh"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 3: Monitor service
echo "Checking monitor service..."
if launchctl list | grep -q com.openclaw.widget-session-monitor; then
    echo "  ✓ Monitor is running"
    PID=$(launchctl list | grep com.openclaw.widget-session-monitor | awk '{print $1}')
    echo "  PID: $PID"
else
    echo "  ✗ Monitor not running"
    echo "  Run: make install"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 4: Log files
echo "Checking log files..."
if [ -f ~/.openclaw/widget-monitor.log ]; then
    echo "  ✓ Log file exists"
    echo "  Last 3 lines:"
    tail -3 ~/.openclaw/widget-monitor.log | sed 's/^/    /'
else
    echo "  ℹ Log file not created yet (monitor may have just started)"
fi
echo ""

# Check 5: Node.js (for manual state writes)
echo "Checking Node.js..."
if command -v node >/dev/null 2>&1; then
    echo "  ✓ Node.js found"
    node --version | sed 's/^/    /'
else
    echo "  ℹ Node.js not found (optional, for manual state writes)"
fi
echo ""

# Check 6: iCloud Drive
echo "Checking iCloud Drive..."
if [ -d ~/Library/Mobile\ Documents/com~apple~CloudDocs ]; then
    echo "  ✓ iCloud Drive accessible"
    if [ -f ~/Library/Mobile\ Documents/com~apple~CloudDocs/openclaw-widget-state.json ]; then
        echo "  ✓ iCloud state file synced"
    else
        echo "  ℹ iCloud state file not synced yet"
    fi
else
    echo "  ℹ iCloud Drive not available (using local file only)"
fi
echo ""

# Summary
echo "======================================"
if [ $ERRORS -eq 0 ]; then
    echo "✅ All checks passed!"
    echo ""
    echo "Next steps:"
    echo "1. Open Xcode and create a new iOS App project"
    echo "2. Add a Widget Extension target"
    echo "3. Copy files from OpenClawWidget/"
    echo "4. Configure App Group: group.com.openclaw.widget"
else
    echo "⚠️  $ERRORS issue(s) found"
    echo ""
    echo "Run: ./setup.sh to fix"
fi
