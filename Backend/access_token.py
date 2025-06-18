from kiteconnect import KiteConnect
import os
from dotenv import load_dotenv, set_key
import webbrowser

def generate_access_token():
    # Load environment variables
    load_dotenv()
    
    # Get API credentials from environment
    api_key = os.getenv('KITE_API_KEY')
    api_secret = os.getenv('KITE_API_SECRET')
    
    if not api_key or not api_secret:
        print("Error: API key or secret not found in .env file")
        print("Please add KITE_API_KEY and KITE_API_SECRET to your .env file")
        return
    
    # Initialize Kite Connect
    kite = KiteConnect(api_key=api_key)
    
    # Get the login URL
    login_url = kite.login_url()
    
    # Open the login URL in default browser
    print(f"\nOpening login URL in your browser...")
    webbrowser.open(login_url)
    
    # Get the request token from user
    print("\nAfter logging in, you will be redirected to a page.")
    print("Please copy the request token from the URL of that page.")
    print("The URL will look like: 'http://127.0.0.1/redirect?request_token=xxxxx&action=login'")
    request_token = input("\nEnter the request token: ").strip()
    
    try:
        # Generate session and get access token
        data = kite.generate_session(request_token, api_secret=api_secret)
        access_token = data["access_token"]
        
        # Save access token to .env file
        set_key('.env', 'KITE_ACCESS_TOKEN', access_token)
        
        print("\nSuccess! Access token has been generated and saved to .env file")
        print(f"Access Token: {access_token}")
        
        return access_token
        
    except Exception as e:
        print(f"\nError generating access token: {e}")
        return None

if __name__ == "__main__":
    print("=== Zerodha Access Token Generator ===")
    generate_access_token()