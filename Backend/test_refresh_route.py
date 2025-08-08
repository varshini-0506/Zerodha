#!/usr/bin/env python3
"""
Test script for the new async refresh token route.
This script tests the job-based approach for the /api/refresh_zerodha_token endpoint.
"""

import requests
import time
import json
import os

def test_refresh_token_route():
    """Test the new async refresh token route"""
    print("=== Testing Async Refresh Token Route ===")
    
    # Get the base URL from environment or use localhost
    base_url = os.getenv('API_BASE_URL', 'http://localhost:5000')
    
    # Test 1: Start the refresh job
    print("\n1. Starting refresh job...")
    try:
        response = requests.post(f"{base_url}/api/refresh_zerodha_token", 
                               json={}, 
                               timeout=10)
        
        if response.status_code == 202:
            data = response.json()
            job_id = data.get('job_id')
            status = data.get('status')
            
            print(f"✅ Job started successfully")
            print(f"   Job ID: {job_id}")
            print(f"   Status: {status}")
            
            # Test 2: Check job result
            print("\n2. Checking job result...")
            max_attempts = 30  # Wait up to 5 minutes
            attempt = 0
            
            while attempt < max_attempts:
                try:
                    result_response = requests.get(f"{base_url}/api/refresh_result/{job_id}", 
                                                timeout=10)
                    
                    if result_response.status_code == 200:
                        result_data = result_response.json()
                        
                        if result_data.get('finished_at'):
                            print(f"✅ Job completed!")
                            print(f"   Success: {result_data.get('success')}")
                            print(f"   Started: {result_data.get('started_at')}")
                            print(f"   Finished: {result_data.get('finished_at')}")
                            
                            if result_data.get('success'):
                                print(f"   Access Token: {result_data.get('access_token', '')[:20]}...")
                                print(f"   Request Token: {result_data.get('request_token', '')[:20]}...")
                            else:
                                print(f"   Error: {result_data.get('error')}")
                                if result_data.get('network_check'):
                                    print(f"   Network Check: {result_data.get('network_check')}")
                            
                            return True
                        else:
                            print(f"   Job still running... (attempt {attempt + 1}/{max_attempts})")
                    else:
                        print(f"   Error checking job result: {result_response.status_code}")
                        
                except requests.exceptions.RequestException as e:
                    print(f"   Request error: {e}")
                
                attempt += 1
                time.sleep(10)  # Wait 10 seconds between checks
            
            print("❌ Job timed out after 5 minutes")
            return False
            
        else:
            print(f"❌ Failed to start job: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Request failed: {e}")
        return False

def test_health_endpoint():
    """Test the health endpoint"""
    print("\n=== Testing Health Endpoint ===")
    
    base_url = os.getenv('API_BASE_URL', 'http://localhost:5000')
    
    try:
        response = requests.get(f"{base_url}/health", timeout=10)
        
        if response.status_code == 200:
            print("✅ Health endpoint working")
            return True
        else:
            print(f"❌ Health endpoint failed: {response.status_code}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Health check failed: {e}")
        return False

def test_market_status():
    """Test the market status endpoint"""
    print("\n=== Testing Market Status Endpoint ===")
    
    base_url = os.getenv('API_BASE_URL', 'http://localhost:5000')
    
    try:
        response = requests.get(f"{base_url}/api/market_status", timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            print("✅ Market status endpoint working")
            print(f"   Status: {data.get('status')}")
            print(f"   Active Symbols: {data.get('active_symbols')}")
            return True
        else:
            print(f"❌ Market status failed: {response.status_code}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Market status check failed: {e}")
        return False

if __name__ == "__main__":
    print("Starting API tests...")
    
    # Test basic endpoints first
    health_ok = test_health_endpoint()
    market_ok = test_market_status()
    
    if not health_ok:
        print("❌ Health check failed - API may not be running")
        exit(1)
    
    if not market_ok:
        print("⚠️  Market status failed - may need authentication")
    
    # Test the refresh token route
    refresh_ok = test_refresh_token_route()
    
    print("\n=== Test Summary ===")
    if refresh_ok:
        print("✅ All tests passed! The async refresh token route is working.")
    else:
        print("❌ Refresh token test failed. Check the logs above for details.")
        print("\nPossible issues:")
        print("- Environment variables not set correctly")
        print("- Chrome/ChromeDriver not working in Docker")
        print("- Network connectivity issues")
        print("- Zerodha credentials invalid")
    
    exit(0 if refresh_ok else 1) 