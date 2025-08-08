#!/usr/bin/env python3
"""
Script to check ChromeDriver installation and debug installation issues
"""

import os
import subprocess
import sys

def check_chrome_installation():
    """Check if Chrome is installed and get its version"""
    print("=== Checking Chrome Installation ===")
    
    chrome_paths = [
        '/usr/bin/google-chrome',
        '/usr/bin/chromium',
        '/usr/bin/chromium-browser'
    ]
    
    chrome_version = None
    for path in chrome_paths:
        if os.path.exists(path):
            try:
                result = subprocess.run([path, '--version'], 
                                      capture_output=True, text=True, timeout=10)
                if result.returncode == 0:
                    print(f"✅ Chrome found at: {path}")
                    print(f"   Version: {result.stdout.strip()}")
                    # Extract version number
                    import re
                    version_match = re.search(r'(\d+\.\d+\.\d+)', result.stdout)
                    if version_match:
                        chrome_version = version_match.group(1)
                        print(f"   Extracted version: {chrome_version}")
                    break
            except Exception as e:
                print(f"   ❌ Error checking {path}: {e}")
    
    if not chrome_version:
        print("❌ Could not determine Chrome version")
        return None
    
    return chrome_version

def check_chromedriver_installation():
    """Check if ChromeDriver is installed"""
    print("\n=== Checking ChromeDriver Installation ===")
    
    chromedriver_paths = [
        '/usr/local/bin/chromedriver',
        '/usr/bin/chromedriver'
    ]
    
    for path in chromedriver_paths:
        if os.path.exists(path):
            try:
                result = subprocess.run([path, '--version'], 
                                      capture_output=True, text=True, timeout=10)
                if result.returncode == 0:
                    print(f"✅ ChromeDriver found at: {path}")
                    print(f"   Version: {result.stdout.strip()}")
                    return path
                else:
                    print(f"❌ ChromeDriver at {path} failed to run: {result.stderr}")
            except Exception as e:
                print(f"❌ Error checking {path}: {e}")
        else:
            print(f"❌ ChromeDriver not found at: {path}")
    
    return None

def install_chromedriver(chrome_version):
    """Install ChromeDriver for the given Chrome version"""
    print(f"\n=== Installing ChromeDriver for Chrome version {chrome_version} ===")
    
    try:
        # Try to get ChromeDriver version for this Chrome version
        version_url = f"https://chromedriver.storage.googleapis.com/LATEST_RELEASE_{chrome_version}"
        print(f"Checking version URL: {version_url}")
        
        import requests
        response = requests.get(version_url, timeout=10)
        if response.status_code == 200:
            chromedriver_version = response.text.strip()
            print(f"✅ Found ChromeDriver version: {chromedriver_version}")
        else:
            print(f"❌ Could not get ChromeDriver version for Chrome {chrome_version}")
            # Try latest version
            response = requests.get("https://chromedriver.storage.googleapis.com/LATEST_RELEASE", timeout=10)
            if response.status_code == 200:
                chromedriver_version = response.text.strip()
                print(f"✅ Using latest ChromeDriver version: {chromedriver_version}")
            else:
                print("❌ Could not get any ChromeDriver version")
                return False
        
        # Download ChromeDriver
        download_url = f"https://chromedriver.storage.googleapis.com/{chromedriver_version}/chromedriver_linux64.zip"
        print(f"Downloading from: {download_url}")
        
        response = requests.get(download_url, timeout=30)
        if response.status_code == 200:
            # Save to temp file
            with open('/tmp/chromedriver.zip', 'wb') as f:
                f.write(response.content)
            print("✅ ChromeDriver downloaded successfully")
            
            # Extract
            import zipfile
            with zipfile.ZipFile('/tmp/chromedriver.zip', 'r') as zip_ref:
                zip_ref.extractall('/tmp/')
            print("✅ ChromeDriver extracted successfully")
            
            # Move to /usr/local/bin
            subprocess.run(['mv', '/tmp/chromedriver', '/usr/local/bin/chromedriver'], check=True)
            subprocess.run(['chmod', '+x', '/usr/local/bin/chromedriver'], check=True)
            subprocess.run(['ln', '-sf', '/usr/local/bin/chromedriver', '/usr/bin/chromedriver'], check=True)
            print("✅ ChromeDriver installed to /usr/local/bin/chromedriver")
            
            # Clean up
            os.remove('/tmp/chromedriver.zip')
            print("✅ Installation completed successfully")
            return True
        else:
            print(f"❌ Failed to download ChromeDriver: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Error during ChromeDriver installation: {e}")
        return False

def main():
    """Main function"""
    print("Starting ChromeDriver installation check...\n")
    
    # Check Chrome installation
    chrome_version = check_chrome_installation()
    if not chrome_version:
        print("❌ Chrome not found or version could not be determined")
        sys.exit(1)
    
    # Check if ChromeDriver is already installed
    chromedriver_path = check_chromedriver_installation()
    if chromedriver_path:
        print("✅ ChromeDriver is already installed and working")
        sys.exit(0)
    
    # Install ChromeDriver
    print("\nChromeDriver not found, attempting installation...")
    if install_chromedriver(chrome_version):
        print("✅ ChromeDriver installation successful")
        
        # Verify installation
        if check_chromedriver_installation():
            print("✅ ChromeDriver verification successful")
            sys.exit(0)
        else:
            print("❌ ChromeDriver verification failed")
            sys.exit(1)
    else:
        print("❌ ChromeDriver installation failed")
        sys.exit(1)

if __name__ == "__main__":
    main() 