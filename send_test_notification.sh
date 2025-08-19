#!/bin/bash

# This script sends a test push notification to the iOS simulator

echo "Sending test push notification to the simulator..."

# Get the booted simulator UDID
BOOTED_SIMULATOR=$(xcrun simctl list devices | grep Booted | head -1 | awk -F'[()]' '{print $2}')

if [ -z "$BOOTED_SIMULATOR" ]; then
  echo "❌ No booted simulator found. Please start a simulator first."
  exit 1
fi

echo "📱 Found booted simulator: $BOOTED_SIMULATOR"

# App bundle identifier
BUNDLE_ID="chathura.Bodima"

# Path to the APNS file
APNS_FILE="/Users/praveen/Documents/GitHub/Bodima/example.apns"

if [ ! -f "$APNS_FILE" ]; then
  echo "❌ APNS file not found at $APNS_FILE"
  exit 1
fi

echo "📄 Using APNS file: $APNS_FILE"

# Send the push notification
echo "🚀 Sending push notification to $BUNDLE_ID..."
xcrun simctl push "$BOOTED_SIMULATOR" "$BUNDLE_ID" "$APNS_FILE"

if [ $? -eq 0 ]; then
  echo "✅ Push notification sent successfully!"
else
  echo "❌ Failed to send push notification."
  exit 1
fi