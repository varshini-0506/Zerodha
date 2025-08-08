#!/usr/bin/env python3
"""
Debug script to check ChromeDriver installation and permissions in Railway
"""

import os
import subprocess
import sys

def check_chromedriver_installation():
    """Check ChromeDriver installation and permissions"""
    print("=== ChromeDriver Installation Debug ===")
    
    # Check environment variables
    chromedriver_bin = os.getenv('CHROMEDRIVER_BIN')
    path = os.getenv('PATH')
    
    print(f"CHROMEDRIVER_BIN: {chromedriver_bin}")
    print(f"PATH: {path}")
    
    # Check common ChromeDriver locations
    chromedriver_paths = [
        '/usr/local/bin/chromedriver',
        '/usr/bin/chromedriver',
        '/opt/chromedriver/chromedriver',
        chromedriver_bin
    ]
    
    for path in chromedriver_paths:
        if path:
            print(f"\n--- Checking {path} ---")
            
            # Check if file exists
            if os.path.exists(path):
                print(f"✅ File exists: {path}")
                
                # Check file permissions
                try:
                    stat = os.stat(path)
                    print(f"   Permissions: {oct(stat.st_mode)[-3:]}")
                    print(f"   Owner: {stat.st_uid}")
                    print(f"   Group: {stat.st_gid}")
                    print(f"   Size: {stat.st_size} bytes")
                except Exception as e:
                    print(f"   ❌ Error checking file stats: {e}")
                
                # Check if executable
                if os.access(path, os.X_OK):
                    print(f"   ✅ File is executable")
                else:
                    print(f"   ❌ File is NOT executable")
                
                # Try to run ChromeDriver
                try:
                    result = subprocess.run([path, '--version'], 
                                          capture_output=True, text=True, timeout=10)
                    if result.returncode == 0:
                        print(f"   ✅ ChromeDriver version: {result.stdout.strip()}")
                    else:
                        print(f"   ❌ ChromeDriver failed: {result.stderr}")
                except Exception as e:
                    print(f"   ❌ Error running ChromeDriver: {e}")
            else:
                print(f"❌ File does not exist: {path}")
    
    # Check which chromedriver
    try:
        result = subprocess.run(['which', 'chromedriver'], 
                              capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            print(f"\n✅ 'which chromedriver' found: {result.stdout.strip()}")
        else:
            print(f"\n❌ 'which chromedriver' not found")
    except Exception as e:
        print(f"\n❌ Error running 'which chromedriver': {e}")
    
    # Check for ChromeDriver in PATH
    try:
        result = subprocess.run(['chromedriver', '--version'], 
                              capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            print(f"✅ 'chromedriver --version' works: {result.stdout.strip()}")
        else:
            print(f"❌ 'chromedriver --version' failed: {result.stderr}")
    except Exception as e:
        print(f"❌ Error running 'chromedriver --version': {e}")

def check_selenium_webdriver():
    """Test Selenium WebDriver creation"""
    print("\n=== Selenium WebDriver Test ===")
    
    try:
        from selenium import webdriver
        from selenium.webdriver.chrome.service import Service
        from selenium.webdriver.chrome.options import Options
        
        print("✅ Selenium imports successful")
        
        # Create Chrome options
        chrome_options = Options()
        chrome_options.add_argument("--headless")
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")
        chrome_options.add_argument("--disable-gpu")
        
        # Try different ChromeDriver approaches
        approaches = [
            ("Auto-detection (no service)", lambda: webdriver.Chrome(options=chrome_options)),
            ("Service with /usr/local/bin/chromedriver", lambda: webdriver.Chrome(service=Service('/usr/local/bin/chromedriver'), options=chrome_options)),
            ("Service with /usr/bin/chromedriver", lambda: webdriver.Chrome(service=Service('/usr/bin/chromedriver'), options=chrome_options)),
        ]
        
        for name, approach in approaches:
            try:
                print(f"\n--- Trying {name} ---")
                driver = approach()
                print(f"✅ {name} successful")
                
                # Test basic functionality
                driver.get("https://www.google.com")
                title = driver.title
                print(f"   Page title: {title}")
                
                driver.quit()
                print(f"   ✅ {name} test completed successfully")
                return True
                
            except Exception as e:
                print(f"❌ {name} failed: {e}")
                continue
        
        print("❌ All WebDriver approaches failed")
        return False
        
    except Exception as e:
        print(f"❌ Selenium test failed: {e}")
        return False

def main():
    """Run all debug checks"""
    print("Starting ChromeDriver debug checks...\n")
    
    check_chromedriver_installation()
    success = check_selenium_webdriver()
    
    print(f"\n=== Debug Summary ===")
    if success:
        print("✅ ChromeDriver is working correctly")
        sys.exit(0)
    else:
        print("❌ ChromeDriver has issues")
        sys.exit(1)

if __name__ == "__main__":
    main() 