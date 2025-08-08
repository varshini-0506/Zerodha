#!/usr/bin/env python3
"""
Test script specifically for Railway deployment to verify Chrome and WebDriver setup
"""

import os
import subprocess
import sys

def test_chrome_installation():
    """Test if Chrome is properly installed in Railway"""
    print("=== Testing Chrome Installation in Railway ===")
    
    # Check environment variables
    chrome_bin = os.getenv("CHROME_BIN")
    chromedriver_bin = os.getenv("CHROMEDRIVER_BIN")
    display = os.getenv("DISPLAY", ":99")
    
    print(f"CHROME_BIN env var: {chrome_bin}")
    print(f"CHROMEDRIVER_BIN env var: {chromedriver_bin}")
    print(f"DISPLAY: {display}")
    
    # Try multiple Chrome binary locations
    chrome_paths = [
        "/usr/bin/google-chrome",
        "/usr/bin/chromium",
        "/usr/bin/chromium-browser",
        "/opt/google/chrome/chrome",
        chrome_bin
    ]
    
    found_chrome = None
    for path in chrome_paths:
        if path and os.path.exists(path):
            try:
                result = subprocess.run([path, '--version'], capture_output=True, text=True, timeout=10)
                if result.returncode == 0:
                    print(f"✅ Chrome found at: {path}")
                    print(f"   Version: {result.stdout.strip()}")
                    found_chrome = path
                    break
            except Exception as e:
                print(f"   ❌ Error testing {path}: {e}")
                continue
    
    if not found_chrome:
        print("❌ No working Chrome binary found")
        print("Available files:")
        try:
            result = subprocess.run(['find', '/usr/bin', '-name', '*chrome*', '-o', '-name', '*chromium*'], 
                                  capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                print(result.stdout)
            else:
                print("No Chrome/Chromium files found")
        except Exception as e:
            print(f"Error searching for Chrome files: {e}")
        return False
    
    # Test ChromeDriver
    print("\n=== Testing ChromeDriver ===")
    chromedriver_paths = [
        "/usr/local/bin/chromedriver",
        "/usr/bin/chromedriver",
        chromedriver_bin
    ]
    
    found_chromedriver = None
    for path in chromedriver_paths:
        if path and os.path.exists(path):
            try:
                result = subprocess.run([path, '--version'], capture_output=True, text=True, timeout=10)
                if result.returncode == 0:
                    print(f"✅ ChromeDriver found at: {path}")
                    print(f"   Version: {result.stdout.strip()}")
                    found_chromedriver = path
                    break
            except Exception as e:
                print(f"   ❌ Error testing {path}: {e}")
                continue
    
    if not found_chromedriver:
        print("❌ No working ChromeDriver found")
        return False
    
    return True

def test_selenium_import():
    """Test if Selenium can be imported"""
    print("\n=== Testing Selenium Import ===")
    try:
        from selenium import webdriver
        from selenium.webdriver.chrome.service import Service
        from selenium.webdriver.chrome.options import Options
        from webdriver_manager.chrome import ChromeDriverManager
        print("✅ Selenium imports successful")
        return True
    except ImportError as e:
        print(f"❌ Selenium import failed: {e}")
        return False

def test_webdriver_creation():
    """Test if WebDriver can be created in Railway"""
    print("\n=== Testing WebDriver Creation ===")
    try:
        from selenium import webdriver
        from selenium.webdriver.chrome.service import Service
        from selenium.webdriver.chrome.options import Options
        from webdriver_manager.chrome import ChromeDriverManager
        
        chrome_options = Options()
        chrome_options.add_argument("--headless")
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")
        chrome_options.add_argument("--disable-gpu")
        chrome_options.add_argument("--disable-software-rasterizer")
        chrome_options.add_argument("--disable-setuid-sandbox")
        chrome_options.add_argument("--remote-debugging-port=9222")
        
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
        
        # Try to create driver with system ChromeDriver first
        try:
            service = Service('/usr/local/bin/chromedriver')
            driver = webdriver.Chrome(service=service, options=chrome_options)
            print("✅ WebDriver created with system ChromeDriver")
        except Exception as e:
            print(f"System ChromeDriver failed: {e}")
            # Fallback to auto-detection
            try:
                driver = webdriver.Chrome(options=chrome_options)
                print("✅ WebDriver created with auto-detection")
            except Exception as e2:
                print(f"Auto-detection also failed: {e2}")
                raise Exception(f"All WebDriver creation methods failed: {e2}")
        
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
    print("Starting Railway Chrome/WebDriver tests...\n")
    
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
        print("✅ All tests passed! Railway setup is ready for Zerodha token recovery.")
        sys.exit(0)
    else:
        print("❌ Some tests failed. Please check the Railway setup.")
        sys.exit(1)

if __name__ == "__main__":
    main() 