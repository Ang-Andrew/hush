#!/bin/bash

# Define variables
APP_LABEL="com.andrewang.hush"
PLIST_PATH="$HOME/Library/LaunchAgents/$APP_LABEL.plist"
BIN_PATH="$(swift build -c release --show-bin-path)/Hush"

# Verify binary exists
if [ ! -f "$BIN_PATH" ]; then
    echo "❌ Error: Release binary not found at $BIN_PATH"
    echo "Please run 'swift build -c release' first."
    exit 1
fi

echo "🚀 Setting up Hush to run on startup..."

# Create the plist file
cat <<EOF > "$PLIST_PATH"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$APP_LABEL</string>
    <key>Program</key>
    <string>$BIN_PATH</string>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/hush.out.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/hush.err.log</string>
</dict>
</plist>
EOF

# Load the service
# We unload first just in case it was already there
launchctl unload "$PLIST_PATH" 2>/dev/null
launchctl load "$PLIST_PATH"

echo "✅ Successfully installed Launch Agent at: $PLIST_PATH"
echo "✅ Hush is now running and will start automatically on login."
echo "📝 Logs are available at /tmp/hush.out.log"
