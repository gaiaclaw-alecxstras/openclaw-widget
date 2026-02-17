#!/usr/bin/env python3
"""
OpenClaw Webhook Sender

Sends state updates via webhook to a relay service.
The relay forwards to APNS or stores for polling.

Usage:
  python3 send-webhook.py --state thinking --tokens 45000
  
Environment:
  OPENCLAW_WEBHOOK_URL - Your webhook endpoint
  OPENCLAW_DEVICE_ID   - Target device identifier
"""

import argparse
import json
import os
import urllib.request
from datetime import datetime


def send_webhook(url: str, device_id: str, state: str, tokens: int, limit: int):
    """Send state update via HTTP webhook"""
    
    payload = {
        "device_id": device_id,
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "openclaw": {
            "state": state,
            "sentiment": get_sentiment(state),
            "token_usage": {
                "current": tokens,
                "limit": limit
            },
            "session_age": 0
        }
    }
    
    data = json.dumps(payload).encode("utf-8")
    
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "Content-Type": "application/json",
            "X-OpenClaw-Event": "state_update"
        },
        method="POST"
    )
    
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            print(f"Webhook sent: {response.status}")
            return True
    except Exception as e:
        print(f"Webhook failed: {e}")
        return False


def get_sentiment(state: str) -> str:
    sentiments = {
        "thinking": "neutral",
        "talking": "positive", 
        "error": "negative",
        "idle": "neutral",
        "offline": "neutral"
    }
    return sentiments.get(state, "neutral")


def save_local_state(state: str, tokens: int, limit: int):
    """Save to local file as fallback"""
    from pathlib import Path
    
    state_data = {
        "state": state,
        "sentiment": get_sentiment(state),
        "token_usage": {"current": tokens, "limit": limit},
        "timestamp": datetime.utcnow().isoformat() + "Z"
    }
    
    state_file = Path.home() / ".openclaw/widget-state-webhook.json"
    state_file.parent.mkdir(parents=True, exist_ok=True)
    state_file.write_text(json.dumps(state_data, indent=2))


def main():
    parser = argparse.ArgumentParser(description="Send OpenClaw state via webhook")
    parser.add_argument("--state", required=True,
                       choices=["idle", "thinking", "talking", "error", "offline"])
    parser.add_argument("--tokens", type=int, default=0)
    parser.add_argument("--limit", type=int, default=200000)
    parser.add_argument("--url", help="Webhook URL (or set OPENCLAW_WEBHOOK_URL)")
    parser.add_argument("--device-id", help="Device ID (or set OPENCLAW_DEVICE_ID)")
    
    args = parser.parse_args()
    
    # Always save locally
    save_local_state(args.state, args.tokens, args.limit)
    
    # Try webhook if configured
    url = args.url or os.environ.get("OPENCLAW_WEBHOOK_URL")
    device_id = args.device_id or os.environ.get("OPENCLAW_DEVICE_ID")
    
    if url and device_id:
        if send_webhook(url, device_id, args.state, args.tokens, args.limit):
            print("✓ Real-time update sent")
        else:
            print("⚠ Webhook failed, using local fallback")
    else:
        print("ℹ No webhook configured, saved locally only")
        print("  Set OPENCLAW_WEBHOOK_URL and OPENCLAW_DEVICE_ID for real-time updates")


if __name__ == "__main__":
    main()
