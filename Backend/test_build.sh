#!/bin/bash

echo "=== Testing ChromeDriver Installation Process ==="

# Check if Chrome is installed
echo "1. Checking Chrome installation..."
if command -v google-chrome &> /dev/null; then
    CHROME_VERSION=$(google-chrome --version | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" | head -1)
    echo "✅ Chrome found: $CHROME_VERSION"
else
    echo "❌ Chrome not found"
    exit 1
fi

# Try to get ChromeDriver version
echo "2. Getting ChromeDriver version..."
VERSION_URL="https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$CHROME_VERSION"
echo "Checking: $VERSION_URL"

if curl -s "$VERSION_URL" > /tmp/chromedriver_version; then
    CHROMEDRIVER_VERSION=$(cat /tmp/chromedriver_version)
    echo "✅ ChromeDriver version: $CHROMEDRIVER_VERSION"
else
    echo "❌ Failed to get ChromeDriver version for Chrome $CHROME_VERSION"
    echo "Trying latest version..."
    if curl -s "https://chromedriver.storage.googleapis.com/LATEST_RELEASE" > /tmp/chromedriver_version; then
        CHROMEDRIVER_VERSION=$(cat /tmp/chromedriver_version)
        echo "✅ Latest ChromeDriver version: $CHROMEDRIVER_VERSION"
    else
        echo "❌ Failed to get any ChromeDriver version"
        exit 1
    fi
fi

# Download ChromeDriver
echo "3. Downloading ChromeDriver..."
DOWNLOAD_URL="https://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip"
echo "Downloading from: $DOWNLOAD_URL"

if curl -s -L "$DOWNLOAD_URL" -o /tmp/chromedriver.zip; then
    echo "✅ ChromeDriver downloaded successfully"
else
    echo "❌ Failed to download ChromeDriver"
    exit 1
fi

# Extract ChromeDriver
echo "4. Extracting ChromeDriver..."
if unzip -q /tmp/chromedriver.zip -d /tmp/; then
    echo "✅ ChromeDriver extracted successfully"
else
    echo "❌ Failed to extract ChromeDriver"
    exit 1
fi

# Check if chromedriver file exists
if [ -f "/tmp/chromedriver" ]; then
    echo "✅ ChromeDriver binary found in /tmp/"
    ls -la /tmp/chromedriver
else
    echo "❌ ChromeDriver binary not found in /tmp/"
    ls -la /tmp/
    exit 1
fi

# Test ChromeDriver
echo "5. Testing ChromeDriver..."
if /tmp/chromedriver --version; then
    echo "✅ ChromeDriver test successful"
else
    echo "❌ ChromeDriver test failed"
    exit 1
fi

# Install ChromeDriver
echo "6. Installing ChromeDriver..."
if mv /tmp/chromedriver /usr/local/bin/chromedriver; then
    echo "✅ ChromeDriver moved to /usr/local/bin/"
else
    echo "❌ Failed to move ChromeDriver"
    exit 1
fi

if chmod +x /usr/local/bin/chromedriver; then
    echo "✅ ChromeDriver permissions set"
else
    echo "❌ Failed to set ChromeDriver permissions"
    exit 1
fi

if ln -sf /usr/local/bin/chromedriver /usr/bin/chromedriver; then
    echo "✅ ChromeDriver symlink created"
else
    echo "❌ Failed to create ChromeDriver symlink"
    exit 1
fi

# Verify installation
echo "7. Verifying installation..."
if /usr/local/bin/chromedriver --version; then
    echo "✅ ChromeDriver installation verified"
else
    echo "❌ ChromeDriver installation verification failed"
    exit 1
fi

# Clean up
echo "8. Cleaning up..."
rm -f /tmp/chromedriver.zip /tmp/chromedriver_version
echo "✅ Cleanup completed"

echo "=== ChromeDriver Installation Test Completed Successfully ===" 