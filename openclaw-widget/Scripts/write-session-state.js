#!/usr/bin/env node
/**
 * OpenClaw Session State Writer
 * 
 * Writes session status to a shared location that the iOS widget can read.
 * Run this from OpenClaw's session hooks or as a background service.
 */

const fs = require('fs');
const path = require('path');
const os = require('os');

// Configuration
const WIDGET_GROUP_CONTAINER = process.env.OPENCLAW_WIDGET_GROUP || 
    path.join(os.homedir(), 'Library', 'Group Containers', 'com.openclaw.widget', 'session-state.json');

const STATE_FILE = process.env.OPENCLAW_STATE_FILE || 
    path.join(os.homedir(), '.openclaw', 'widget-session-state.json');

// Ensure directory exists
function ensureDir(filePath) {
    const dir = path.dirname(filePath);
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
}

/**
 * Write session state to the shared file
 * @param {Object} state - Session state object
 */
function writeSessionState(state) {
    const stateData = {
        date: new Date().toISOString(),
        state: state.state || 'idle',
        tokenUsage: {
            current: state.tokenUsage?.current || 0,
            limit: state.tokenUsage?.limit || 200000
        },
        model: state.model || 'unknown',
        sessionAge: state.sessionAge || 0
    };

    // Write to both locations (widget can pick either)
    const json = JSON.stringify(stateData, null, 2);
    
    try {
        ensureDir(STATE_FILE);
        fs.writeFileSync(STATE_FILE, json, 'utf8');
        
        // Also try to write to App Group if accessible
        if (process.env.OPENCLAW_WIDGET_GROUP) {
            ensureDir(WIDGET_GROUP_CONTAINER);
            fs.writeFileSync(WIDGET_GROUP_CONTAINER, json, 'utf8');
        }
        
        console.log('Session state written:', stateData.state);
    } catch (err) {
        console.error('Failed to write session state:', err.message);
    }
}

/**
 * Parse OpenClaw session status output and write state
 */
function parseAndWriteStatus(statusOutput) {
    // Parse the status output format:
    // "Sessions: Kind Key Age Model Tokens (ctx %)"
    
    const lines = statusOutput.split('\n');
    const sessionLine = lines.find(l => l.includes('agent:main'));
    
    if (!sessionLine) {
        writeSessionState({ state: 'offline' });
        return;
    }

    // Extract tokens: "55k/200k (27%)"
    const tokenMatch = sessionLine.match(/(\d+)k\/(\d+)k \((\d+)%\)/);
    const ageMatch = sessionLine.match(/(\d+)(m|h)\s+ago/);
    const modelMatch = sessionLine.match(/kimi-[\w-]+/);
    
    const current = tokenMatch ? parseInt(tokenMatch[1]) * 1000 : 0;
    const limit = tokenMatch ? parseInt(tokenMatch[2]) * 1000 : 200000;
    const age = ageMatch ? parseInt(ageMatch[1]) * (ageMatch[2] === 'h' ? 3600 : 60) : 0;
    const model = modelMatch ? modelMatch[0] : 'unknown';
    
    // Determine state based on activity
    let state = 'idle';
    if (sessionLine.includes('thinking') || sessionLine.includes('reasoning')) {
        state = 'thinking';
    } else if (sessionLine.includes('active') || age < 60) {
        state = 'talking';
    }
    
    writeSessionState({
        state,
        tokenUsage: { current, limit },
        model,
        sessionAge: age
    });
}

// CLI usage
if (require.main === module) {
    const args = process.argv.slice(2);
    
    if (args[0] === '--status' && args[1]) {
        // Read status from file or stdin
        const status = fs.existsSync(args[1]) 
            ? fs.readFileSync(args[1], 'utf8')
            : args[1];
        parseAndWriteStatus(status);
    } else if (args[0] === '--state') {
        // Direct state write
        writeSessionState({
            state: args[1] || 'idle',
            tokenUsage: { current: parseInt(args[2]) || 0, limit: 200000 },
            model: args[3] || 'unknown',
            sessionAge: parseInt(args[4]) || 0
        });
    } else {
        console.log(`
Usage:
  node write-session-state.js --status "<openclaw status output>"
  node write-session-state.js --state <idle|thinking|talking|error> [tokens] [model] [age]

Environment:
  OPENCLAW_STATE_FILE    - Path to state file (default: ~/.openclaw/widget-session-state.json)
  OPENCLAW_WIDGET_GROUP  - App Group container path for direct iOS widget access
        `.trim());
    }
}

module.exports = { writeSessionState, parseAndWriteStatus };
