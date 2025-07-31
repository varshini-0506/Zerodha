#!/usr/bin/env python3
"""
Test script to debug WebDriver connection issues
"""

import os
import time
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager

def test_webdriver_creation():
    """Test WebDriver creation step by step"""
    print("=== Testing WebDriver Creation ===")
    
    # Basic Chrome options
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--disable-web-security")
    chrome_options.add_argument("--allow-running-insecure-content")
    chrome_options.add_argument("--disable-features=VizDisplayCompositor")
    chrome_options.add_argument("--disable-software-rasterizer")
    chrome_options.add_argument("--disable-background-timer-throttling")
    chrome_options.add_argument("--disable-backgrounding-occluded-windows")
    chrome_options.add_argument("--disable-renderer-backgrounding")
    chrome_options.add_argument("--disable-features=TranslateUI")
    chrome_options.add_argument("--disable-ipc-flooding-protection")
    chrome_options.add_argument("--disable-default-apps")
    chrome_options.add_argument("--disable-sync")
    chrome_options.add_argument("--no-first-run")
    chrome_options.add_argument("--no-default-browser-check")
    chrome_options.add_argument("--disable-background-networking")
    chrome_options.add_argument("--disable-component-extensions-with-background-pages")
    chrome_options.add_argument("--disable-client-side-phishing-detection")
    chrome_options.add_argument("--disable-hang-monitor")
    chrome_options.add_argument("--disable-prompt-on-repost")
    chrome_options.add_argument("--disable-domain-reliability")
    chrome_options.add_argument("--remote-debugging-port=9222")
    chrome_options.add_argument("--remote-debugging-address=0.0.0.0")
    chrome_options.add_experimental_option("excludeSwitches", ["enable-automation"])
    chrome_options.add_experimental_option("useAutomationExtension", False)
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
    
    try:
        print("1. Installing ChromeDriver...")
        chromedriver_path = ChromeDriverManager().install()
        print(f"   ChromeDriver installed at: {chromedriver_path}")
        
        print("2. Creating ChromeService...")
        service = Service(executable_path=chromedriver_path)
        
        print("3. Creating WebDriver...")
        driver = webdriver.Chrome(
            service=service,
            options=chrome_options
        )
        
        print("4. Setting timeouts...")
        driver.set_page_load_timeout(60)
        driver.implicitly_wait(10)
        
        print("5. Testing with Google...")
        driver.get("https://www.google.com")
        print(f"   Google title: {driver.title}")
        
        print("6. Testing with Zerodha...")
        driver.get("https://kite.zerodha.com")
        print(f"   Zerodha title: {driver.title}")
        
        print("7. Testing login page...")
        login_url = "https://kite.zerodha.com/connect/login?v=3&api_key=i3lwf5icae8f9ukq"
        driver.get(login_url)
        print(f"   Login page title: {driver.title}")
        
        print("8. Looking for form elements...")
        try:
            userid_field = driver.find_element(By.ID, "userid")
            print("   ✓ User ID field found")
        except Exception as e:
            print(f"   ✗ User ID field not found: {e}")
        
        try:
            password_field = driver.find_element(By.ID, "password")
            print("   ✓ Password field found")
        except Exception as e:
            print(f"   ✗ Password field not found: {e}")
        
        print("9. Closing WebDriver...")
        driver.quit()
        
        print("✅ All tests passed!")
        return True
        
    except Exception as e:
        print(f"❌ Test failed: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    test_webdriver_creation() 