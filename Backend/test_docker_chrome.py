#!/usr/bin/env python3
"""
Test script to verify Chrome and ChromeDriver installation in Docker environment.
This script should be run to ensure the /api/refresh_zerodha_token route will work.
"""

import os
import sys
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.common.exceptions import WebDriverException

def test_chrome_installation():
    """Test Chrome and ChromeDriver installation"""
    print("=== Testing Chrome and ChromeDriver Installation ===")
    
    # Check environment variables
    print(f"CHROME_BIN: {os.getenv('CHROME_BIN', 'Not set')}")
    print(f"CHROMEDRIVER_PATH: {os.getenv('CHROMEDRIVER_PATH', 'Not set')}")
    
    # Check if Chrome binary exists
    chrome_paths = [
        "/usr/bin/chromium",
        "/usr/bin/google-chrome",
        "/usr/bin/chromium-browser"
    ]
    
    chrome_found = False
    for path in chrome_paths:
        if os.path.exists(path):
            print(f"✅ Chrome found at: {path}")
            chrome_found = True
            break
    
    if not chrome_found:
        print("❌ Chrome binary not found")
        return False
    
    # Check ChromeDriver paths
    chromedriver_paths = [
        "/usr/lib/chromium/chromedriver",
        "/usr/local/bin/chromedriver",
        "/usr/bin/chromedriver"
    ]
    
    chromedriver_found = False
    chromedriver_path = None
    
    for path in chromedriver_paths:
        if os.path.exists(path):
            print(f"✅ ChromeDriver found at: {path}")
            chromedriver_found = True
            chromedriver_path = path
            break
    
    if not chromedriver_found:
        print("❌ ChromeDriver not found")
        return False
    
    # Test ChromeDriver with Selenium
    print("\n=== Testing ChromeDriver with Selenium ===")
    
    try:
        # Chrome options for headless mode
        chrome_options = Options()
        chrome_options.binary_location = "/usr/bin/chromium"
        chrome_options.add_argument("--headless")
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-gpu")
        chrome_options.add_argument("--disable-dev-shm-usage")
        chrome_options.add_argument("--disable-software-rasterizer")
        chrome_options.add_argument("--disable-setuid-sandbox")
        chrome_options.add_argument("--dns-prefetch-disable")
        chrome_options.add_argument("--window-size=1920,1080")
        
        # Create service and driver
        service = Service(executable_path=chromedriver_path)
        driver = webdriver.Chrome(service=service, options=chrome_options)
        
        # Test navigation
        print("✅ ChromeDriver created successfully")
        driver.get("https://www.google.com")
        print(f"✅ Successfully navigated to Google. Title: {driver.title}")
        
        # Test screenshot capability
        screenshot = driver.get_screenshot_as_png()
        print(f"✅ Screenshot capability working. Size: {len(screenshot)} bytes")
        
        driver.quit()
        print("✅ ChromeDriver test completed successfully")
        return True
        
    except WebDriverException as e:
        print(f"❌ ChromeDriver test failed: {e}")
        return False
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False

def test_environment_variables():
    """Test if required environment variables are set"""
    print("\n=== Testing Environment Variables ===")
    
    required_vars = [
        "KITE_USERNAME",
        "KITE_PASSWORD", 
        "TOTP_SECRET",
        "KITE_API_KEY",
        "KITE_API_SECRET",
        "SUPABASE_URL",
        "SUPABASE_KEY"
    ]
    
    missing_vars = []
    for var in required_vars:
        value = os.getenv(var)
        if value:
            print(f"✅ {var}: Set")
        else:
            print(f"❌ {var}: Not set")
            missing_vars.append(var)
    
    if missing_vars:
        print(f"\n⚠️  Missing environment variables: {', '.join(missing_vars)}")
        print("These are required for the /api/refresh_zerodha_token route to work.")
        return False
    else:
        print("\n✅ All required environment variables are set")
        return True

if __name__ == "__main__":
    print("Starting Chrome/ChromeDriver test for Zerodha token refresh...")
    
    chrome_test = test_chrome_installation()
    env_test = test_environment_variables()
    
    print("\n=== Test Summary ===")
    if chrome_test and env_test:
        print("✅ All tests passed! The /api/refresh_zerodha_token route should work.")
        sys.exit(0)
    else:
        print("❌ Some tests failed. Check the output above for details.")
        sys.exit(1) 