#!/bin/bash

echo "=== Starting Zerodha Backend in Docker ==="
echo "Current directory: $(pwd)"
echo "Environment variables:"
echo "CHROME_BIN: $CHROME_BIN"
echo "PORT: $PORT"

# Test Chrome and ChromeDriver installation
echo "=== Testing Chrome and ChromeDriver Installation ==="
python test_docker_chrome.py
if [ $? -ne 0 ]; then
    echo "⚠️  Chrome/ChromeDriver test failed, but continuing with Flask app..."
else
    echo "✅ Chrome/ChromeDriver test passed!"
fi

echo "=== Starting Flask application ==="
# Set default port if not provided
PORT=${PORT:-10000}
echo "Using port: $PORT"

# Start the Flask application with gunicorn
exec gunicorn --bind 0.0.0.0:$PORT app:app --workers 2 --threads 2 