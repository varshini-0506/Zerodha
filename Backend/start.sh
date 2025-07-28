#!/bin/bash

# Start virtual display for Selenium
Xvfb :99 -screen 0 1920x1080x24 > /dev/null 2>&1 &

# Wait a moment for Xvfb to start
sleep 2

# Start the Flask application
exec gunicorn --worker-class gevent --workers 1 --bind 0.0.0.0:$PORT app:app 