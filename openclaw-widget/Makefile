.PHONY: setup install uninstall clean test

# Default target
all: setup

# Run the setup script
setup:
	@echo "🌿 Setting up OpenClaw Widget..."
	@./setup.sh

# Install the monitor service only
install:
	@mkdir -p ~/Library/LaunchAgents
	@sed "s|~|$(HOME)|g" Scripts/com.openclaw.widget-session-monitor.plist > ~/Library/LaunchAgents/com.openclaw.widget-session-monitor.plist
	@launchctl unload ~/Library/LaunchAgents/com.openclaw.widget-session-monitor.plist 2>/dev/null || true
	@launchctl load ~/Library/LaunchAgents/com.openclaw.widget-session-monitor.plist
	@echo "✓ Monitor service installed"

# Uninstall the monitor service
uninstall:
	@launchctl unload ~/Library/LaunchAgents/com.openclaw.widget-session-monitor.plist 2>/dev/null || true
	@rm -f ~/Library/LaunchAgents/com.openclaw.widget-session-monitor.plist
	@echo "✓ Monitor service removed"

# Restart the monitor
restart:
	@launchctl unload ~/Library/LaunchAgents/com.openclaw.widget-session-monitor.plist 2>/dev/null || true
	@launchctl load ~/Library/LaunchAgents/com.openclaw.widget-session-monitor.plist
	@echo "✓ Monitor restarted"

# View logs
logs:
	@tail -f ~/.openclaw/widget-monitor.log

# Check status
status:
	@echo "Monitor status:"
	@launchctl list | grep openclaw || echo "Not running"
	@echo ""
	@echo "State file:"
	@cat ~/.openclaw/widget-session-state.json 2>/dev/null || echo "Not found"

# Test write a state
test:
	@node Scripts/write-session-state.js --state thinking 55000 kimi-k2-thinking 120
	@echo "✓ Test state written"
	@cat ~/.openclaw/widget-session-state.json

# Clean up generated files
clean:
	@rm -f ~/.openclaw/widget-session-state.json
	@rm -f ~/.openclaw/widget-monitor.log
	@rm -f ~/.openclaw/widget-monitor.error.log
	@echo "✓ Cleaned up state files"

# Help
help:
	@echo "OpenClaw Widget Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  setup      - Full setup (installs monitor, creates state file)"
	@echo "  install    - Install monitor service only"
	@echo "  uninstall  - Remove monitor service"
	@echo "  restart    - Restart monitor service"
	@echo "  logs       - View monitor logs"
	@echo "  status     - Check monitor status and current state"
	@echo "  test       - Write a test state"
	@echo "  clean      - Remove generated files"
