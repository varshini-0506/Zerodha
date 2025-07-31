#!/bin/bash

echo "=== Starting Zerodha Backend ==="
echo "Current directory: $(pwd)"
echo "Environment variables:"
echo "CHROME_BIN: $CHROME_BIN"
echo "DISPLAY: $DISPLAY"

echo "=== Checking Chrome binary ==="
# Check for Google Chrome first
if [ -f "/usr/bin/google-chrome" ]; then
    echo "✅ Google Chrome found: $(/usr/bin/google-chrome --version)"
    export CHROME_BIN=/usr/bin/google-chrome
elif [ -f "/usr/bin/chromium" ]; then
    echo "✅ Chromium found: $(/usr/bin/chromium --version)"
    export CHROME_BIN=/usr/bin/chromium
elif [ -f "/usr/bin/chromium-browser" ]; then
    echo "✅ Chromium browser found: $(/usr/bin/chromium-browser --version)"
    export CHROME_BIN=/usr/bin/chromium-browser
else
    echo "❌ No Chrome/Chromium binary found"
    echo "Available browsers:"
    ls -la /usr/bin/*chrome* /usr/bin/*chromium* 2>/dev/null || echo "No browser binaries found"
fi

echo "=== Chrome binary path: $CHROME_BIN ==="

# Start virtual display for Selenium
echo "=== Starting virtual display ==="
Xvfb :99 -screen 0 1920x1080x24 > /dev/null 2>&1 &

# Wait a moment for Xvfb to start
sleep 2

# Run Railway Chrome test to verify setup
echo "=== Running Railway Chrome test ==="
python test_railway_chrome.py
if [ $? -ne 0 ]; then
    echo "❌ Railway Chrome test failed. Starting Flask app anyway..."
else
    echo "✅ Railway Chrome test passed!"
fi

echo "=== Starting Flask application ==="
# Set default port if not provided
PORT=${PORT:-5000}
echo "Using port: $PORT"
# Start the Flask application
exec gunicorn --worker-class gevent --workers 1 --bind 0.0.0.0:$PORT app:app 