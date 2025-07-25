# backend/server.py
from gevent import monkey
monkey.patch_all()
# Standard library imports
import asyncio
import json
import threading
import os
from typing import Dict, List, Optional
from datetime import datetime, timedelta, time , date
import pytz
import traceback

# Third-party imports
from flask import Flask, jsonify, request
from flask_cors import CORS
import websockets
from kiteconnect import KiteConnect, KiteTicker
from dotenv import load_dotenv
import requests
from supabase import create_client, Client
from flask_socketio import SocketIO, emit


# Load environment variables
load_dotenv()

app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": "*"}})
socketio = SocketIO(app, cors_allowed_origins="*", async_mode="gevent")

# Get credentials from environment variables
API_KEY = os.getenv('KITE_API_KEY')
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_ROLE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
FINNHUB_API_KEY = os.getenv('FINNHUB_API_KEY')
FMP_API_KEY = os.getenv("FMP_API_KEY")

def fetch_access_token_from_supabase():
    """
    Fetch the latest access token for Zerodha from the Supabase 'api_tokens' table.
    """
    response = supabase.table("api_tokens").select("access_token").eq("service", "zerodha").single().execute()
    if response.data and "access_token" in response.data:
        return response.data["access_token"]
    else:
        raise ValueError("Access token for Zerodha not found in Supabase.")

ACCESS_TOKEN = fetch_access_token_from_supabase()

if not API_KEY or not ACCESS_TOKEN:
    raise ValueError("Please set KITE_API_KEY in .env and ensure access token is available in Supabase.")

# Initialize Kite Connect
kite = KiteConnect(api_key=API_KEY)
kite.set_access_token(ACCESS_TOKEN)

# Store latest tick data
latest_ticks = {}

# Cache for instruments data
instruments_cache = {}
instruments_cache_timestamp = None

SUPABASE_WISHLIST_ENDPOINT = f'{SUPABASE_URL}/rest/v1/wishlist'
SUPABASE_HEADERS = {
    'apikey': SUPABASE_SERVICE_ROLE_KEY,
    'Authorization': f'Bearer {SUPABASE_SERVICE_ROLE_KEY}',
    'Content-Type': 'application/json'
}

def get_all_instruments():
    """Get all available instruments from NSE"""
    global instruments_cache, instruments_cache_timestamp
    
    # Cache for 1 hour
    if (instruments_cache_timestamp and 
        (datetime.now() - instruments_cache_timestamp).seconds < 3600):
        return instruments_cache
    
    try:
        instruments = kite.instruments("NSE")
        instruments_cache = instruments
        instruments_cache_timestamp = datetime.now()
        print(f"Fetched {len(instruments)} instruments from NSE")
        return instruments
    except Exception as e:
        print(f"Error fetching instruments: {e}")
        return []

def get_popular_stocks():
    """Get list of popular stocks with basic info"""
    try:
        instruments = get_all_instruments()
        popular_symbols = [
            "RELIANCE", "TCS", "HDFCBANK", "INFY", "ICICIBANK",
            "HINDUNILVR", "HDFC", "SBIN", "BHARTIARTL", "ITC",
            "KOTAKBANK", "LT", "AXISBANK", "MARUTI", "ASIANPAINT",
            "WIPRO", "HCLTECH", "ULTRACEMCO", "TITAN", "BAJFINANCE",
            "TATAMOTORS", "SUNPHARMA", "POWERGRID", "TECHM", "NTPC",
            "ADANIENT", "ADANIPORTS", "BAJAJFINSV", "BAJAJ-AUTO", "COALINDIA"
        ]
        
        popular_stocks = []
        for instrument in instruments:
            if instrument['tradingsymbol'] in popular_symbols:
                stock_data = {
                    'symbol': instrument['tradingsymbol'],
                    'name': instrument['name'],
                    'instrument_token': instrument['instrument_token'],
                    'exchange': instrument['exchange'],
                    'instrument_type': instrument['instrument_type'],
                    'segment': instrument['segment'],
                    'expiry': instrument['expiry'],
                    'strike': instrument['strike'],
                    'tick_size': instrument['tick_size'],
                    'lot_size': instrument['lot_size']
                }
                popular_stocks.append(stock_data)
        
        return popular_stocks
    except Exception as e:
        print(f"Error getting popular stocks: {e}")
        return []

@app.route('/api/stocks', methods=['GET'])
def get_stocks():
    """Get all available stocks with pagination and search"""
    try:
        page = int(request.args.get('page', 1))
        limit = int(request.args.get('limit', 50))
        search = request.args.get('search', '').upper()
        
        instruments = get_all_instruments()
        
        # Filter by search term if provided
        if search:
            instruments = [i for i in instruments if search in i['tradingsymbol'] or search in i['name'].upper()]
        
        # Pagination
        start_idx = (page - 1) * limit
        end_idx = start_idx + limit
        paginated_instruments = instruments[start_idx:end_idx]
        
        # Format response
        stocks = []
        for instrument in paginated_instruments:
            stock_data = {
                'symbol': instrument['tradingsymbol'],
                'name': instrument['name'],
                'instrument_token': instrument['instrument_token'],
                'exchange': instrument['exchange'],
                'instrument_type': instrument['instrument_type'],
                'segment': instrument['segment'],
                'expiry': instrument['expiry'],
                'strike': instrument['strike'],
                'tick_size': instrument['tick_size'],
                'lot_size': instrument['lot_size']
            }
            stocks.append(stock_data)
        
        return jsonify({
            'stocks': stocks,
            'total': len(instruments),
            'page': page,
            'limit': limit,
            'has_next': end_idx < len(instruments),
            'has_prev': page > 1
        })
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/stocks/popular', methods=['GET'])
def get_popular_stocks_endpoint():
    """Get popular stocks"""
    try:
        stocks = get_popular_stocks()
        return jsonify({'stocks': stocks})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/stocks/<symbol>', methods=['GET'])
def get_stock_detail(symbol):
    """Get detailed information for a specific stock"""
    try:
        # Get instrument details
        instruments = get_all_instruments()
        instrument = None
        
        for inst in instruments:
            if inst['tradingsymbol'] == symbol.upper():
                instrument = inst
                break
        
        if not instrument:
            return jsonify({"error": "Stock not found"}), 404
        
        # Get quote data
        quote_data = None
        try:
            quote = kite.quote(f"NSE:{symbol.upper()}")
            if f"NSE:{symbol.upper()}" in quote:
                quote_data = quote[f"NSE:{symbol.upper()}"]
                # Add change and change_percent to quote_data if possible
                last_price = quote_data.get('last_price')
                ohlc = quote_data.get('ohlc', {})
                close = ohlc.get('close') if ohlc else quote_data.get('close')
                if close is None:
                    close = quote_data.get('close')
                if last_price is not None and close not in (None, 0):
                    change = last_price - close
                    change_percent = ((last_price - close) / close) * 100 if close != 0 else 0
                    quote_data['change'] = change
                    quote_data['change_percent'] = change_percent
        except Exception as e:
            print(f"Error fetching quote for {symbol}: {e}")
        
        # Get historical data (last 30 days)
        historical_data = None
        try:
            from datetime import timedelta
            end_date = datetime.now()
            start_date = end_date - timedelta(days=30)
            
            historical = kite.historical_data(
                instrument_token=instrument['instrument_token'],
                from_date=start_date.date(),
                to_date=end_date.date(),
                interval='day'
            )
            historical_data = historical
        except Exception as e:
            print(f"Error fetching historical data for {symbol}: {e}")
        
        # Compile detailed stock information
        stock_detail = {
            'symbol': instrument['tradingsymbol'],
            'name': instrument['name'],
            'instrument_token': instrument['instrument_token'],
            'exchange': instrument['exchange'],
            'instrument_type': instrument['instrument_type'],
            'segment': instrument['segment'],
            'expiry': instrument['expiry'],
            'strike': instrument['strike'],
            'tick_size': instrument['tick_size'],
            'lot_size': instrument['lot_size'],
            'quote': quote_data,
            'historical_data': historical_data,
            'last_updated': datetime.now().isoformat()
        }
        
        return jsonify(stock_detail)
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/market_status', methods=['GET'])
def get_market_status():
    """Get current market status"""
    try:
        return jsonify({
            "status": "success",
            "timestamp": datetime.now().isoformat(),
            "active_symbols": len(latest_ticks),
            "total_symbols": len(get_all_instruments()),
            "market_open": True  # You can add logic to check if market is open
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/search', methods=['GET'])
def search_stocks():
    """Search stocks by symbol or name"""
    try:
        query = request.args.get('q', '').strip()
        if not query:
            return jsonify({"error": "Query parameter 'q' is required"}), 400
        
        instruments = get_all_instruments()
        query_upper = query.upper()
        
        # Search by symbol or name
        results = []
        for instrument in instruments:
            if (query_upper in instrument['tradingsymbol'] or 
                query_upper in instrument['name'].upper()):
                stock_data = {
                    'symbol': instrument['tradingsymbol'],
                    'name': instrument['name'],
                    'instrument_token': instrument['instrument_token'],
                    'exchange': instrument['exchange'],
                    'instrument_type': instrument['instrument_type']
                }
                results.append(stock_data)
                
                # Limit results to 20
                if len(results) >= 20:
                    break
        
        return jsonify({'results': results, 'query': query})
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/news', methods=['GET'])
def get_news():
    """Get market news from multiple sources"""
    try:
        import requests
        from xml.etree import ElementTree
        
        news_items = []
        
        # Try to fetch from Zerodha Pulse RSS feed
        try:
            response = requests.get('https://pulse.zerodha.com/feed.php', timeout=10)
            if response.status_code == 200:
                root = ElementTree.fromstring(response.content)
                for item in root.findall('.//item'):
                    title = item.find('title')
                    link = item.find('link')
                    description = item.find('description')
                    pubDate = item.find('pubDate')
                    
                    if title is not None and link is not None:
                        news_items.append({
                            'title': title.text or '',
                            'link': link.text or '',
                            'description': description.text if description is not None else '',
                            'pubDate': pubDate.text if pubDate is not None else '',
                            'source': 'Zerodha Pulse'
                        })
        except Exception as e:
            print(f"Error fetching from Zerodha Pulse: {e}")
        
        # If no news from Zerodha, try alternative sources
        if not news_items:
            # Try MoneyControl RSS feed
            try:
                response = requests.get('https://www.moneycontrol.com/rss/business.xml', timeout=10)
                if response.status_code == 200:
                    root = ElementTree.fromstring(response.content)
                    for item in root.findall('.//item'):
                        title = item.find('title')
                        link = item.find('link')
                        description = item.find('description')
                        pubDate = item.find('pubDate')
                        
                        if title is not None and link is not None:
                            news_items.append({
                                'title': title.text or '',
                                'link': link.text or '',
                                'description': description.text if description is not None else '',
                                'pubDate': pubDate.text if pubDate is not None else '',
                                'source': 'MoneyControl'
                            })
            except Exception as e:
                print(f"Error fetching from MoneyControl: {e}")
        
        # If still no news, provide sample news
        if not news_items:
            news_items = [
                {
                    'title': 'Market Update: Sensex and Nifty show positive momentum',
                    'link': 'https://example.com/news1',
                    'description': 'Indian markets opened higher today with strong buying in banking and IT stocks.',
                    'pubDate': 'Mon, 23 Jun 2025 20:49:46 +0530',
                    'source': 'Market Update'
                },
                {
                    'title': 'RBI announces new monetary policy measures',
                    'link': 'https://example.com/news2',
                    'description': 'The Reserve Bank of India has announced new measures to support economic growth.',
                    'pubDate': 'Mon, 23 Jun 2025 19:30:00 +0530',
                    'source': 'RBI News'
                },
                {
                    'title': 'Global markets react to economic data',
                    'link': 'https://example.com/news3',
                    'description': 'International markets are responding to the latest economic indicators.',
                    'pubDate': 'Mon, 23 Jun 2025 18:15:00 +0530',
                    'source': 'Global Markets'
                }
            ]
        
        return jsonify({
            'news': news_items,
            'count': len(news_items),
            'timestamp': datetime.now().isoformat()
        })
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/wishlist', methods=['POST'])
def add_to_wishlist():
    """Add a stock to a user's wishlist in Supabase"""
    data = request.get_json()
    user_id = data.get('user_id')
    symbol = data.get('symbol')
    if not user_id or not symbol:
        return jsonify({'error': 'user_id and symbol are required'}), 400
    payload = {'user_id': user_id, 'symbol': symbol}
    response = requests.post(SUPABASE_WISHLIST_ENDPOINT, headers=SUPABASE_HEADERS, json=payload)
    if response.status_code in (200, 201):
        return jsonify({'message': f'Stock {symbol} added to wishlist for user {user_id}.'}), 200
    else:
        return jsonify({'error': response.text}), response.status_code

@app.route('/api/wishlist/<user_id>', methods=['GET'])
def get_wishlist(user_id):
    """Get all wishlisted stocks for a particular user from Supabase"""
    params = {'user_id': f'eq.{user_id}'}
    response = requests.get(SUPABASE_WISHLIST_ENDPOINT, headers=SUPABASE_HEADERS, params=params)
    if response.status_code == 200:
        wishlist = [item['symbol'] for item in response.json()]
        return jsonify({'user_id': user_id, 'wishlist': wishlist}), 200
    else:
        return jsonify({'error': response.text}), response.status_code

@app.route('/api/wishlist/details/<user_id>', methods=['GET'])
def get_wishlist_details(user_id):
    """Get all wishlisted stocks for a user, including full stock details for each symbol."""
    try:
        print(f"Fetching wishlist details for user: {user_id}")
        params = {'user_id': f'eq.{user_id}'}
        response = requests.get(SUPABASE_WISHLIST_ENDPOINT, headers=SUPABASE_HEADERS, params=params)
        if response.status_code != 200:
            print("Supabase error:", response.text)
            return jsonify({'error': response.text}), response.status_code
        wishlist = [item['symbol'] for item in response.json()]
        print(f"Wishlist symbols: {wishlist}")
        print(f"Wishlist length: {len(wishlist)}")
        stock_details = []
        for symbol in wishlist:
            print(f"Processing symbol: {symbol}")
            try:
                instruments = get_all_instruments()
                print(f"Number of instruments: {len(instruments)}")
                instrument = None
                for inst in instruments:
                    if inst['tradingsymbol'] == symbol.upper():
                        instrument = inst
                        break
                if not instrument:
                    print(f"Instrument not found for symbol: {symbol}")
                    continue
                # Fetch quote data
                quote_data = None
                try:
                    quote = kite.quote(f"NSE:{symbol.upper()}")
                    if f"NSE:{symbol.upper()}" in quote:
                        quote_data = quote[f"NSE:{symbol.upper()}"]
                        last_price = quote_data.get('last_price')
                        ohlc = quote_data.get('ohlc', {})
                        close = ohlc.get('close') if ohlc else quote_data.get('close')
                        if close is None:
                            close = quote_data.get('close')
                        if last_price is not None and close not in (None, 0):
                            change = last_price - close
                            change_percent = ((last_price - close) / close) * 100 if close != 0 else 0
                            quote_data['change'] = change
                            quote_data['change_percent'] = change_percent
                except Exception as e:
                    print(f"Error fetching quote for {symbol}: {e}")
                # Fetch historical data (last 30 days)
                historical_data = None
                try:
                    from datetime import timedelta
                    end_date = datetime.now()
                    start_date = end_date - timedelta(days=30)
                    historical = kite.historical_data(
                        instrument_token=instrument['instrument_token'],
                        from_date=start_date.date(),
                        to_date=end_date.date(),
                        interval='day'
                    )
                    historical_data = historical
                except Exception as e:
                    print(f"Error fetching historical data for {symbol}: {e}")
                stock_detail = {
                    'symbol': instrument['tradingsymbol'],
                    'name': instrument['name'],
                    'instrument_token': instrument['instrument_token'],
                    'exchange': instrument['exchange'],
                    'instrument_type': instrument['instrument_type'],
                    'segment': instrument['segment'],
                    'expiry': instrument['expiry'],
                    'strike': instrument['strike'],
                    'tick_size': instrument['tick_size'],
                    'lot_size': instrument['lot_size'],
                    'quote': quote_data,
                    'historical_data': historical_data,
                    'last_updated': datetime.now().isoformat()
                }
                stock_details.append(stock_detail)
            except Exception as e:
                print(f"Error processing wishlist symbol {symbol}: {e}")
                traceback.print_exc()
                continue
        return jsonify({'user_id': user_id, 'wishlist': wishlist, 'stock_details': stock_details}), 200
    except Exception as e:
        print("Top-level error:", e)
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

@app.route('/api/wishlist', methods=['DELETE'])
def remove_from_wishlist():
    """Remove a stock from a user's wishlist in Supabase"""
    data = request.get_json()
    user_id = data.get('user_id')
    symbol = data.get('symbol')
    if not user_id or not symbol:
        return jsonify({'error': 'user_id and symbol are required'}), 400
    params = {
        'user_id': f'eq.{user_id}',
        'symbol': f'eq.{symbol}'
    }
    response = requests.delete(
        SUPABASE_WISHLIST_ENDPOINT,
        headers=SUPABASE_HEADERS,
        params=params
    )
    if response.status_code in (200, 204):
        return jsonify({'message': f'Stock {symbol} removed from wishlist for user {user_id}.'}), 200
    else:
        return jsonify({'error': response.text}), response.status_code

@app.route('/api/recover_zerodha_token', methods=['POST'])
def recover_zerodha_token_route():
    """Recover Zerodha access token and store in Supabase"""
    import time
    import pyotp
    from selenium import webdriver
    from selenium.webdriver.chrome.service import Service
    from selenium.webdriver.common.by import By
    from selenium.webdriver.chrome.options import Options
    from selenium.webdriver.support.ui import WebDriverWait
    from selenium.webdriver.support import expected_conditions as EC
    from kiteconnect import KiteConnect
    from supabase import create_client, Client
    from webdriver_manager.chrome import ChromeDriverManager
    from selenium.common.exceptions import StaleElementReferenceException

    # Load environment variables
    load_dotenv()
    USER_ID = os.getenv("KITE_USERNAME")
    PASSWORD = os.getenv("KITE_PASSWORD")
    TOTP_SECRET = os.getenv("TOTP_SECRET")
    API_KEY = os.getenv("KITE_API_KEY")
    API_SECRET = os.getenv("KITE_API_SECRET")
    SUPABASE_URL = os.getenv("SUPABASE_URL")
    SUPABASE_KEY = os.getenv("SUPABASE_KEY")

    # Supabase setup
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

    opts = Options()
    opts.add_argument("--start-maximized")
    opts.add_argument("--disable-blink-features=AutomationControlled")
    opts.add_experimental_option("excludeSwitches", ["enable-automation"])
    opts.add_experimental_option("useAutomationExtension", False)
    # opts.add_argument("--headless")  # Disabled for debugging
    opts.add_argument("--no-sandbox")
    opts.add_argument("--disable-dev-shm-usage")
    opts.binary_location ="C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"
    driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=opts)
    wait = WebDriverWait(driver, 30)
    result = {"success": False, "access_token": None, "error": None, "request_token": None, "supabase_response": None}
    try:
        # Step 1: Navigate to Zerodha login
        login_url = f"https://kite.zerodha.com/connect/login?v=3&api_key={API_KEY}"
        driver.get(login_url)

        # Step 2: Enter username and password
        print("Filling username...")
        username_field = wait.until(EC.presence_of_element_located((By.ID, "userid")))
        username_field.send_keys(USER_ID)
        print("Filling password...")
        driver.find_element(By.ID, "password").send_keys(PASSWORD)
        print("Submitting login form...")
        driver.find_element(By.CSS_SELECTOR, "button[type='submit']").click()

        print("Waiting for TOTP field to be clickable (after page navigation)...")
        totp_field = wait.until(EC.element_to_be_clickable((By.ID, "userid")))
        print("TOTP field found, entering TOTP...")
        totp = pyotp.TOTP(TOTP_SECRET).now()
        totp_field.clear()
        totp_field.send_keys(totp)
        print("TOTP entered, submitting form...")
        driver.find_element(By.CSS_SELECTOR, "button[type='submit']").click()

        # Wait for the URL to contain 'request_token=' after TOTP submit
        print("Waiting for request_token in URL...")
        wait.until(lambda d: "request_token=" in d.current_url)
        request_token = driver.current_url.split("request_token=")[-1].split("&")[0]
        print("Request token found:", request_token)
        result["request_token"] = request_token

        # Close the browser immediately after extracting the request token
        driver.quit()
        driver = None

        # Step 5: Exchange request_token for access_token using KiteConnect
        kite = KiteConnect(api_key=API_KEY)
        data = kite.generate_session(request_token, api_secret=API_SECRET)
        access_token = data["access_token"]
        result["access_token"] = access_token

        # Step 6: Store in Supabase
        response = supabase.table("api_tokens").upsert({
            "service": "zerodha",
            "access_token": access_token,
            "created_at": datetime.now().isoformat()
        }, on_conflict="service").execute()
        result["supabase_response"] = response.data
        result["success"] = True
    except Exception as e:
        import traceback
        print(traceback.format_exc())
        result["error"] = str(e)
    finally:
        # Only call driver.quit() if the driver is still open
        try:
            if driver is not None:
                driver.quit()
        except:
            pass
    return jsonify(result)

@app.route('/api/stock_events/<symbol>', methods=['GET'])
def get_combined_stock_events(symbol):
    today = datetime.today()
    one_year_ago = today - timedelta(days=365)
    today_str = today.strftime('%Y-%m-%d')
    one_year_ago_str = one_year_ago.strftime('%Y-%m-%d')

    # Finnhub URLs
    earnings_url = f'https://finnhub.io/api/v1/stock/earnings?symbol={symbol}&token={FINNHUB_API_KEY}'
    ipo_url = f'https://finnhub.io/api/v1/calendar/ipo?from={today_str}&to={(today + timedelta(days=30)).strftime("%Y-%m-%d")}&token={FINNHUB_API_KEY}'

    # FMP URLs
    base_fmp_url = "https://financialmodelingprep.com/api/v3"
    dividends_url = f"{base_fmp_url}/historical-price-full/stock_dividend/{symbol}?apikey={FMP_API_KEY}"
    splits_url = f"{base_fmp_url}/historical-price-full/stock_split/{symbol}?apikey={FMP_API_KEY}"

    try:
        # Fetch Finnhub data
        earnings = requests.get(earnings_url).json()
        ipos = requests.get(ipo_url).json().get("ipoCalendar", [])

        # Fetch FMP data
        dividends = requests.get(dividends_url).json()
        splits = requests.get(splits_url).json()

        return jsonify({
            "symbol": symbol,
            "earnings_finnhub": earnings,
            "ipos_finnhub": ipos,
            "dividends_fmp": dividends,
            "splits_fmp": splits
        })

    except Exception as e:
        return jsonify({"error": "Failed to fetch stock events", "details": str(e)}), 500

def on_ticks(ws, ticks):
    """Callback when ticks are received"""
    for tick in ticks:
        instrument_token = tick["instrument_token"]
        
        # Get instrument details for symbol
        symbol = None
        tradingsymbol = None
        for instrument in get_all_instruments():
            if instrument['instrument_token'] == instrument_token:
                symbol = instrument['tradingsymbol']
                tradingsymbol = instrument['tradingsymbol']
                break
        
        # Store tick data with symbol information
        latest_ticks[instrument_token] = {
            "instrument_token": instrument_token,
            "symbol": symbol,
            "tradingsymbol": tradingsymbol,
            "last_price": tick.get("last_price", 0),
            "ltp": tick.get("last_price", 0),  # Alternative field name
            "volume": tick.get("volume", 0),
            "change": tick.get("change", 0),
            "high": tick.get("high", 0),
            "low": tick.get("low", 0),
            "open": tick.get("open", 0),
            "close": tick.get("close", 0),
            "timestamp": datetime.now().isoformat()
        }
    print(f"Received ticks for {len(ticks)} instruments")

def on_connect(ws, response):
    """Callback when connection is established"""
    # Subscribe only to popular stocks to avoid exceeding the 4000 instrument limit
    popular_symbols = [
        "RELIANCE", "TCS", "HDFCBANK", "INFY", "ICICIBANK",
        "HINDUNILVR", "HDFC", "SBIN", "BHARTIARTL", "ITC",
        "KOTAKBANK", "LT", "AXISBANK", "MARUTI", "ASIANPAINT",
        "WIPRO", "HCLTECH", "ULTRACEMCO", "TITAN", "BAJFINANCE",
        "TATAMOTORS", "SUNPHARMA", "POWERGRID", "TECHM", "NTPC",
        "ADANIENT", "ADANIPORTS", "BAJAJFINSV", "BAJAJ-AUTO", "COALINDIA"
    ]
    instruments = get_all_instruments()
    instrument_tokens = [inst['instrument_token'] for inst in instruments if inst['tradingsymbol'] in popular_symbols]

    ws.subscribe(instrument_tokens)
    ws.set_mode(ws.MODE_FULL, instrument_tokens)

    print(f"WebSocket connected and subscribed to {len(instrument_tokens)} popular instruments")

def on_error(ws, code, reason):
    """Callback when error occurs"""
    print(f"WebSocket error. Code: {code}, Reason: {reason}")

def on_close(ws, code, reason):
    """Callback when connection closes"""
    print(f"WebSocket closed. Code: {code}, Reason: {reason}")

def start_kite_ws():
    """Start WebSocket connection with Kite"""
    kws = KiteTicker(API_KEY, ACCESS_TOKEN)
    kws.on_ticks = on_ticks
    kws.on_connect = on_connect
    kws.on_close = on_close
    kws.on_error = on_error
    
    while True:
        try:
            kws.connect(threaded=True)
            break
        except Exception as e:
            print(f"Error connecting to WebSocket: {e}")
            print("Retrying in 5 seconds...")
            import time
            time.sleep(5)

def background_tick_sender():
    import time
    while True:
        if latest_ticks:
            ticks_list = list(latest_ticks.values())
            socketio.emit('tick_data', {'data': ticks_list, 'timestamp': datetime.now().isoformat()})
        time.sleep(0.1)

@socketio.on('connect')
def handle_connect():
    emit('market_status', {
        "status": "connected",
        "timestamp": datetime.now().isoformat(),
        "total_instruments": len(get_all_instruments())
    })

if __name__ == "__main__":
    print("Starting Zerodha WebSocket streamer...")
    # Start background tasks using SocketIO's method
    socketio.start_background_task(start_kite_ws)
    socketio.start_background_task(background_tick_sender)
    socketio.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", 5000)))
