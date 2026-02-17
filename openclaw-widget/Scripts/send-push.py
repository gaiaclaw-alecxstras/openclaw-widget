#!/usr/bin/env python3
"""
OpenClaw Push Notification Sender

Sends push notifications to update the iOS widget state.
This runs on the OpenClaw agent side when state changes.

Usage:
  python3 send-push.py --state thinking --tokens 45000
  python3 send-push.py --state talking
  python3 send-push.py --state idle

Requires:
  - APNS certificate or token
  - Device token for target iOS device
  - Environment variables set (see below)
"""

import argparse
import json
import ssl
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

# Configuration - set these environment variables or edit here
APNS_KEY_ID = "YOUR_KEY_ID"  # From Apple Developer portal
APNS_TEAM_ID = "YOUR_TEAM_ID"  # Your Apple Developer Team ID
APNS_BUNDLE_ID = "com.openclaw.widget.app"  # Your app bundle ID
DEVICE_TOKEN = None  # Will be read from file or env

# Sandbox vs Production
APNS_HOST = "api.sandbox.push.apple.com"  # Use api.push.apple.com for production


def send_push(device_token: str, state: str, tokens_used: int = 0, total_tokens: int = 200000, message: str = ""):
    """Send push notification via APNS HTTP/2 API"""
    
    import http.client
    import jwt
    
    # Build JWT token
    token = jwt.encode(
        {
            "iss": APNS_TEAM_ID,
            "iat": time.time(),
            "exp": time.time() + 3600  # 1 hour expiry
        },
        open(Path.home() / ".openclaw/apns_key.p8", "rb").read(),
        algorithm="ES256",
        headers={"kid": APNS_KEY_ID}
    )
    
    # Build notification payload
    payload = {
        "aps": {
            "alert": {
                "title": "OpenClaw",
                "body": message or f"State: {state}"
            },
            "mutable-content": 1,
            "category": "openclaw_state",
            "sound": "default" if state in ["talking", "error"] else None
        },
        "openclaw": {
            "state": state,
            "sentiment": get_sentiment(state),
            "token_usage": {
                "current": tokens_used,
                "limit": total_tokens
            },
            "session_age": 0,
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
    }
    
    # Send via HTTP/2
    conn = http.client.HTTPSConnection(APNS_HOST)
    conn.request(
        "POST",
        f"/3/device/{device_token}",
        body=json.dumps(payload),
        headers={
            "authorization": f"bearer {token}",
            "apns-topic": APNS_BUNDLE_ID,
            "apns-push-type": "alert"
        }
    )
    
    response = conn.getresponse()
    print(f"APNS Response: {response.status} {response.reason}")
    print(response.read().decode())
    conn.close()


def get_sentiment(state: str) -> str:
    """Map state to sentiment"""
    sentiments = {
        "thinking": "neutral",
        "talking": "positive",
        "error": "negative",
        "idle": "neutral",
        "offline": "neutral"
    }
    return sentiments.get(state, "neutral")


def save_local_state(state: str, tokens_used: int, total_tokens: int):
    """Also save state locally for fallback"""
    state_data = {
        "state": state,
        "sentiment": get_sentiment(state),
        "token_usage": {
            "current": tokens_used,
            "limit": total_tokens
        },
        "timestamp": datetime.utcnow().isoformat() + "Z"
    }
    
    # Save to file (fallback if push fails)
    state_file = Path.home() / ".openclaw/widget-state-push.json"
    state_file.parent.mkdir(parents=True, exist_ok=True)
    state_file.write_text(json.dumps(state_data, indent=2))
    
    print(f"State saved: {state}")


def main():
    parser = argparse.ArgumentParser(description="Send OpenClaw state push notification")
    parser.add_argument("--state", required=True, 
                       choices=["idle", "thinking", "talking", "error", "offline"],
                       help="Agent state")
    parser.add_argument("--tokens", type=int, default=0,
                       help="Current token usage")
    parser.add_argument("--limit", type=int, default=200000,
                       help="Token limit")
    parser.add_argument("--message", default="",
                       help="Custom notification message")
    parser.add_argument("--device-token", 
                       help="iOS device token (or set OPENCLAW_DEVICE_TOKEN env)")
    parser.add_argument("--local-only", action="store_true",
                       help="Only save locally, don't send push")
    
    args = parser.parse_args()
    
    # Get device token
    device_token = args.device_token or os.environ.get("OPENCLAW_DEVICE_TOKEN")
    
    # Always save locally first
    save_local_state(args.state, args.tokens, args.limit)
    
    if args.local_only or not device_token:
        print("Saved locally only (no push sent)")
        return
    
    # Try to send push
    try:
        send_push(device_token, args.state, args.tokens, args.limit, args.message)
    except Exception as e:
        print(f"Push failed: {e}")
        print("State was saved locally for widget fallback")


if __name__ == "__main__":
    import os
    main()
