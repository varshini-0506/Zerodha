#!/bin/bash

echo "=== Starting Zerodha Backend ==="
echo "Current directory: $(pwd)"
echo "Environment variables:"
echo "CHROME_BIN: $CHROME_BIN"
echo "CHROMEDRIVER_BIN: $CHROMEDRIVER_BIN"
echo "DISPLAY: $DISPLAY"

echo "=== Checking Chrome binaries ==="
ls -la /usr/bin/chromium* || echo "No chromium binaries found"
ls -la /usr/bin/chromedriver || echo "chromedriver not found"

echo "=== Checking which commands ==="
which chromium || echo "chromium not found"
which chromium-browser || echo "chromium-browser not found"
which chromedriver || echo "chromedriver not found"

# Start virtual display for Selenium
echo "=== Starting virtual display ==="
Xvfb :99 -screen 0 1920x1080x24 > /dev/null 2>&1 &

# Wait a moment for Xvfb to start
sleep 2

echo "=== Starting Flask application ==="
# Start the Flask application
exec gunicorn --worker-class gevent --workers 1 --bind 0.0.0.0:$PORT app:app 