#!/usr/bin/env python3
"""
Comprehensive ChromeDriver installation debug script
"""

import os
import subprocess
import sys

def check_system_info():
    """Check basic system information"""
    print("=== System Information ===")
    print(f"Python version: {sys.version}")
    print(f"Current working directory: {os.getcwd()}")
    print(f"User: {os.getenv('USER', 'unknown')}")
    print(f"Home directory: {os.getenv('HOME', 'unknown')}")

def check_environment_variables():
    """Check all Chrome-related environment variables"""
    print("\n=== Environment Variables ===")
    chrome_vars = [
        'CHROME_BIN', 'CHROMEDRIVER_PATH', 'CHROMEDRIVER_BIN',
        'SELENIUM_DRIVER_PATH', 'WDM_LOCAL', 'WDM_SSL_VERIFY',
        'WDM_CACHE_PATH', 'DISPLAY', 'PATH'
    ]
    
    for var in chrome_vars:
        value = os.getenv(var)
        print(f"{var}: {value}")

def check_chrome_installation():
    """Check Chrome/Chromium installation"""
    print("\n=== Chrome/Chromium Installation ===")
    
    chrome_paths = [
        '/usr/bin/chromium',
        '/usr/bin/google-chrome',
        '/usr/bin/chromium-browser',
        '/opt/google/chrome/chrome'
    ]
    
    for path in chrome_paths:
        if os.path.exists(path):
            try:
                result = subprocess.run([path, '--version'], 
                                      capture_output=True, text=True, timeout=10)
                if result.returncode == 0:
                    print(f"✅ Chrome found at: {path}")
                    print(f"   Version: {result.stdout.strip()}")
                else:
                    print(f"❌ Chrome at {path} failed to run: {result.stderr}")
            except Exception as e:
                print(f"❌ Error testing {path}: {e}")
        else:
            print(f"❌ Chrome not found at: {path}")

def check_chromedriver_installation():
    """Check ChromeDriver installation in detail"""
    print("\n=== ChromeDriver Installation ===")
    
    chromedriver_paths = [
        '/usr/lib/chromium/chromedriver',
        '/usr/local/bin/chromedriver',
        '/usr/bin/chromedriver',
        '/opt/chromedriver/chromedriver',
        '/snap/bin/chromedriver'
    ]
    
    found_chromedrivers = []
    
    for path in chromedriver_paths:
        print(f"\n--- Checking {path} ---")
        
        if os.path.exists(path):
            print(f"✅ File exists: {path}")
            
            # Check file permissions
            try:
                stat = os.stat(path)
                print(f"   Permissions: {oct(stat.st_mode)[-3:]}")
                print(f"   Owner: {stat.st_uid}")
                print(f"   Group: {stat.st_gid}")
                print(f"   Size: {stat.st_size} bytes")
                
                # Check if executable
                if os.access(path, os.X_OK):
                    print(f"   ✅ File is executable")
                else:
                    print(f"   ❌ File is NOT executable")
                    
            except Exception as e:
                print(f"   ❌ Error checking file stats: {e}")
            
            # Try to run ChromeDriver
            try:
                result = subprocess.run([path, '--version'], 
                                      capture_output=True, text=True, timeout=10)
                if result.returncode == 0:
                    print(f"   ✅ ChromeDriver version: {result.stdout.strip()}")
                    found_chromedrivers.append(path)
                else:
                    print(f"   ❌ ChromeDriver failed: {result.stderr}")
            except Exception as e:
                print(f"   ❌ Error running ChromeDriver: {e}")
        else:
            print(f"❌ File does not exist: {path}")
    
    return found_chromedrivers

def check_package_installation():
    """Check if ChromeDriver package is installed"""
    print("\n=== Package Installation Check ===")
    
    # Check if chromium-driver package is installed
    try:
        result = subprocess.run(['dpkg', '-l', '|', 'grep', 'chromium'], 
                              shell=True, capture_output=True, text=True)
        print("Installed chromium packages:")
        print(result.stdout)
    except Exception as e:
        print(f"Error checking packages: {e}")
    
    # Check if chromedriver is in PATH
    try:
        result = subprocess.run(['which', 'chromedriver'], 
                              capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ chromedriver found in PATH: {result.stdout.strip()}")
        else:
            print("❌ chromedriver not found in PATH")
    except Exception as e:
        print(f"Error checking PATH: {e}")

def check_file_system():
    """Check file system for ChromeDriver files"""
    print("\n=== File System Search ===")
    
    search_paths = [
        '/usr/lib/chromium',
        '/usr/local/bin',
        '/usr/bin',
        '/opt',
        '/snap/bin'
    ]
    
    for search_path in search_paths:
        if os.path.exists(search_path):
            print(f"\n--- Searching in {search_path} ---")
            try:
                result = subprocess.run(['find', search_path, '-name', '*chrome*', '-o', '-name', '*chromium*'], 
                                      capture_output=True, text=True, timeout=30)
                if result.stdout.strip():
                    print("Found files:")
                    for line in result.stdout.strip().split('\n'):
                        if line:
                            print(f"  {line}")
                else:
                    print("No Chrome/Chromium files found")
            except Exception as e:
                print(f"Error searching {search_path}: {e}")
        else:
            print(f"❌ Directory does not exist: {search_path}")

def check_selenium_imports():
    """Check Selenium imports and basic functionality"""
    print("\n=== Selenium Import Check ===")
    
    try:
        from selenium import webdriver
        from selenium.webdriver.chrome.service import Service
        from selenium.webdriver.chrome.options import Options
        print("✅ All Selenium imports successful")
        return True
    except ImportError as e:
        print(f"❌ Selenium import failed: {e}")
        return False

def test_webdriver_creation(chromedriver_paths):
    """Test WebDriver creation with available ChromeDriver paths"""
    print("\n=== WebDriver Creation Test ===")
    
    if not check_selenium_imports():
        return False
    
    from selenium import webdriver
    from selenium.webdriver.chrome.service import Service
    from selenium.webdriver.chrome.options import Options
    
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--disable-gpu")
    
    for path in chromedriver_paths:
        try:
            print(f"\n--- Testing WebDriver with {path} ---")
            service = Service(executable_path=path)
            driver = webdriver.Chrome(service=service, options=chrome_options)
            print(f"✅ WebDriver created successfully with {path}")
            
            # Test basic functionality
            driver.get("https://www.google.com")
            title = driver.title
            print(f"   ✅ Basic navigation test passed. Page title: {title}")
            
            driver.quit()
            print(f"   ✅ WebDriver closed successfully")
            return True
            
        except Exception as e:
            print(f"❌ WebDriver creation failed with {path}: {e}")
            continue
    
    return False

def main():
    """Run all debug checks"""
    print("=== ChromeDriver Installation Debug ===")
    print("Starting comprehensive ChromeDriver installation check...\n")
    
    # Run all checks
    check_system_info()
    check_environment_variables()
    check_chrome_installation()
    found_chromedrivers = check_chromedriver_installation()
    check_package_installation()
    check_file_system()
    
    # Test WebDriver creation if ChromeDriver found
    if found_chromedrivers:
        print(f"\nFound {len(found_chromedrivers)} ChromeDriver(s): {found_chromedrivers}")
        webdriver_success = test_webdriver_creation(found_chromedrivers)
        if webdriver_success:
            print("\n✅ ChromeDriver is working correctly!")
            sys.exit(0)
        else:
            print("\n❌ ChromeDriver found but WebDriver creation failed")
            sys.exit(1)
    else:
        print("\n❌ No working ChromeDriver found")
        sys.exit(1)

if __name__ == "__main__":
    main() 