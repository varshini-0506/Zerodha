#!/usr/bin/env python3
"""
Test script to verify Chrome and ChromeDriver setup in Docker container
"""

import os
import subprocess
import sys

def test_chrome_installation():
    """Test if Chrome is properly installed"""
    print("=== Testing Chrome Installation ===")
    
    # Check environment variables
    chrome_bin = os.getenv("CHROME_BIN", "/usr/bin/google-chrome")
    display = os.getenv("DISPLAY", ":99")
    
    print(f"CHROME_BIN: {chrome_bin}")
    print(f"DISPLAY: {display}")
    
    # Try multiple Chrome binary locations
    chrome_paths = [
        "/usr/bin/google-chrome",
        "/usr/bin/chromium",
        "/usr/bin/chromium-browser",
        chrome_bin
    ]
    
    found_chrome = None
    for path in chrome_paths:
        try:
            result = subprocess.run(['ls', '-la', path], capture_output=True, text=True)
            if result.returncode == 0:
                print(f"✅ Chrome binary found at: {path}")
                found_chrome = path
                break
        except Exception:
            continue
    
    if not found_chrome:
        print("❌ No Chrome binary found in common locations")
        return False
    
    # Test Chrome version
    try:
        result = subprocess.run([chrome_bin, '--version'], capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ Chrome version: {result.stdout.strip()}")
        else:
            print(f"❌ Error getting Chrome version: {result.stderr}")
            return False
    except Exception as e:
        print(f"❌ Error testing Chrome version: {e}")
        return False
    
    return True

def test_selenium_import():
    """Test if Selenium can be imported"""
    print("\n=== Testing Selenium Import ===")
    try:
        from selenium import webdriver
        from selenium.webdriver.chrome.service import Service
        from selenium.webdriver.chrome.options import Options
        print("✅ Selenium imports successful")
        return True
    except ImportError as e:
        print(f"❌ Selenium import failed: {e}")
        return False

def test_webdriver_creation():
    """Test if WebDriver can be created"""
    print("\n=== Testing WebDriver Creation ===")
    try:
        from selenium import webdriver
        from selenium.webdriver.chrome.service import Service
        from selenium.webdriver.chrome.options import Options
        from webdriver_manager.chrome import ChromeDriverManager
        from selenium.webdriver.chrome.service import Service as ChromeService
        
        chrome_options = Options()
        chrome_options.add_argument("--headless")
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")
        chrome_options.add_argument("--disable-gpu")
        chrome_options.add_argument("--disable-software-rasterizer")
        chrome_options.add_argument("--disable-setuid-sandbox")
        
        # Try to find Chrome binary
        chrome_bin = os.getenv("CHROME_BIN")
        if not chrome_bin:
            for path in ["/usr/bin/google-chrome", "/usr/bin/chromium", "/usr/bin/chromium-browser"]:
                if os.path.exists(path):
                    chrome_bin = path
                    break
        
        if chrome_bin:
            chrome_options.binary_location = chrome_bin
            print(f"Using Chrome binary: {chrome_bin}")
        else:
            print("No Chrome binary found, using default")
        
        driver = webdriver.Chrome(
            service=ChromeService(ChromeDriverManager().install()),
            options=chrome_options
        )
        
        print("✅ WebDriver created successfully")
        
        # Test basic navigation
        driver.get("https://www.google.com")
        title = driver.title
        print(f"✅ Basic navigation test passed. Page title: {title}")
        
        driver.quit()
        print("✅ WebDriver closed successfully")
        return True
        
    except Exception as e:
        print(f"❌ WebDriver creation failed: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """Run all tests"""
    print("Starting Docker Chrome/ChromeDriver tests...\n")
    
    tests = [
        test_chrome_installation,
        test_selenium_import,
        test_webdriver_creation
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        if test():
            passed += 1
        print()
    
    print(f"=== Test Results ===")
    print(f"Passed: {passed}/{total}")
    
    if passed == total:
        print("✅ All tests passed! Docker setup is ready for Zerodha token recovery.")
        sys.exit(0)
    else:
        print("❌ Some tests failed. Please check the Docker setup.")
        sys.exit(1)

if __name__ == "__main__":
    main() 