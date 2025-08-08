# backend/server.py
from gevent import monkey
monkey.patch_all()
# Standard library imports
import asyncio
import json
import threading
import os
import socket
from typing import Dict, List, Optional
from datetime import datetime, timedelta, time , date
import pytz
import traceback
from email.utils import parsedate_to_datetime

# Third-party imports
from flask import Flask, jsonify, request
from flask_cors import CORS
import websockets
from kiteconnect import KiteConnect, KiteTicker
from dotenv import load_dotenv
import requests
from supabase import create_client, Client
from flask_socketio import SocketIO, emit
import pyotp
import base64

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.service import Service as ChromeService
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.chrome.options import Options
from urllib.parse import urlparse, parse_qs

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
        
        # Convert timestamps to IST timezone
        ist_timezone = pytz.timezone('Asia/Kolkata')
        
        # Convert historical data timestamps
        if historical_data:
            for candle in historical_data:
                try:
                    original_date = candle['date']
                    
                    if isinstance(original_date, str):
                        # Handle string format like "Sun, 01 Jan 2023 18:30:00 GMT"
                        if 'GMT' in original_date:
                            gmt_dt = parsedate_to_datetime(original_date)
                            ist_dt = gmt_dt.astimezone(ist_timezone)
                        else:
                            # Handle ISO format
                            gmt_dt = datetime.fromisoformat(original_date.replace('Z', '+00:00'))
                            ist_dt = gmt_dt.astimezone(ist_timezone)
                    else:
                        # Handle datetime object
                        ist_dt = original_date.astimezone(ist_timezone)
                    
                    # Format with day name, date, time and timezone
                    formatted_date = ist_dt.strftime('%A, %d %b %Y %H:%M:%S %Z')
                    candle['date'] = formatted_date
                    
                except Exception as e:
                    print(f"Error converting timezone for historical candle {candle}: {e}")
                    continue
        
        # Convert quote data timestamps if they exist
        if quote_data:
            # Convert timestamp field
            if 'timestamp' in quote_data:
                try:
                    original_timestamp = quote_data['timestamp']
                    if isinstance(original_timestamp, str):
                        if 'GMT' in original_timestamp:
                            gmt_dt = parsedate_to_datetime(original_timestamp)
                            ist_dt = gmt_dt.astimezone(ist_timezone)
                        else:
                            gmt_dt = datetime.fromisoformat(original_timestamp.replace('Z', '+00:00'))
                            ist_dt = gmt_dt.astimezone(ist_timezone)
                    else:
                        ist_dt = original_timestamp.astimezone(ist_timezone)
                    
                    quote_data['timestamp'] = ist_dt.strftime('%A, %d %b %Y %H:%M:%S %Z')
                except Exception as e:
                    print(f"Error converting quote timestamp: {e}")
            
            # Convert last_trade_time field
            if 'last_trade_time' in quote_data:
                try:
                    original_trade_time = quote_data['last_trade_time']
                    if isinstance(original_trade_time, str):
                        if 'GMT' in original_trade_time:
                            gmt_dt = parsedate_to_datetime(original_trade_time)
                            ist_dt = gmt_dt.astimezone(ist_timezone)
                        else:
                            gmt_dt = datetime.fromisoformat(original_trade_time.replace('Z', '+00:00'))
                            ist_dt = gmt_dt.astimezone(ist_timezone)
                    else:
                        ist_dt = original_trade_time.astimezone(ist_timezone)
                    
                    quote_data['last_trade_time'] = ist_dt.strftime('%A, %d %b %Y %H:%M:%S %Z')
                except Exception as e:
                    print(f"Error converting last_trade_time: {e}")
        
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
            'last_updated': datetime.now(ist_timezone).strftime('%A, %d %b %Y %H:%M:%S %Z'),
            'timezone': 'Asia/Kolkata (IST)'
        }
        
        return jsonify(stock_detail)
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/stocks/batch_quotes', methods=['POST'])
def get_batch_quotes():
    """Get quote data for multiple stocks in a single request"""
    try:
        data = request.get_json()
        symbols = data.get('symbols', [])
        
        if not symbols:
            return jsonify({"error": "Symbols list is required"}), 400
        
        # Limit to 50 symbols to prevent abuse
        if len(symbols) > 50:
            symbols = symbols[:50]
        
        quotes = {}
        instruments = get_all_instruments()
        
        # Prepare instrument tokens for batch quote
        instrument_tokens = []
        symbol_to_token = {}
        
        for symbol in symbols:
            symbol_upper = symbol.upper()
            for inst in instruments:
                if inst['tradingsymbol'] == symbol_upper:
                    instrument_tokens.append(inst['instrument_token'])
                    symbol_to_token[symbol_upper] = inst['instrument_token']
                    break
        
        if not instrument_tokens:
            return jsonify({"quotes": {}})
        
        try:
            # Get batch quotes from Zerodha
            batch_quotes = kite.quote([f"NSE:{symbol}" for symbol in symbols])
            
            # Process each quote
            for symbol in symbols:
                symbol_upper = symbol.upper()
                quote_key = f"NSE:{symbol_upper}"
                
                if quote_key in batch_quotes:
                    quote_data = batch_quotes[quote_key]
                    
                    # Calculate change and change_percent
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
                    
                    quotes[symbol_upper] = quote_data
                else:
                    quotes[symbol_upper] = None
                    
        except Exception as e:
            print(f"Error fetching batch quotes: {e}")
            # Return empty quotes if batch fails
            for symbol in symbols:
                quotes[symbol.upper()] = None
        
        return jsonify({
            "quotes": quotes,
            "timestamp": datetime.now().isoformat()
        })
        
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

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint for uptime monitoring"""
    return "OK", 200

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

import base64
import socket
import requests
from flask import jsonify
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
import os, pyotp
from kiteconnect import KiteConnect
from urllib.parse import urlparse, parse_qs
from datetime import datetime
from supabase import create_client
# Removed ChromeDriver import - using webdriver.Chrome instead

@app.route("/api/refresh_zerodha_token", methods=["POST"])
def refresh_zerodha_token():
    result = {
        "success": False,
        "access_token": "",
        "request_token": "",
        "error": "",
        "supabase_response": "",
        "debug_screenshot": "",
        "debug_html": "",
        "network_check": ""
    }

    driver = None
    try:
        # Load and validate secrets
        Z_USERNAME = os.getenv("KITE_USERNAME", "").strip()
        Z_PASSWORD = os.getenv("KITE_PASSWORD", "").strip()
        TOTP_SECRET = os.getenv("TOTP_SECRET", "").strip()
        API_KEY = os.getenv("KITE_API_KEY", "").strip()
        API_SECRET = os.getenv("KITE_API_SECRET", "").strip()
        SUPABASE_URL = os.getenv("SUPABASE_URL", "").strip()
        SUPABASE_KEY = os.getenv("SUPABASE_KEY", "").strip()

        # Validate all required environment variables
        missing_vars = []
        if not Z_USERNAME: missing_vars.append("KITE_USERNAME")
        if not Z_PASSWORD: missing_vars.append("KITE_PASSWORD")
        if not TOTP_SECRET: missing_vars.append("TOTP_SECRET")
        if not API_KEY: missing_vars.append("KITE_API_KEY")
        if not API_SECRET: missing_vars.append("KITE_API_SECRET")
        if not SUPABASE_URL: missing_vars.append("SUPABASE_URL")
        if not SUPABASE_KEY: missing_vars.append("SUPABASE_KEY")

        if missing_vars:
            result["error"] = f"Missing required environment variables: {', '.join(missing_vars)}"
            result["success"] = False
            return jsonify(result)

        # Validate TOTP secret early
        try:
            pyotp.TOTP(TOTP_SECRET).now()
        except Exception as e:
            result["error"] = f"Invalid TOTP_SECRET: {str(e)}"
            result["success"] = False
            return jsonify(result)

        # Network diagnostics
        debug_msg = []
        try:
            ip = socket.gethostbyname("kite.zerodha.com")
            debug_msg.append(f"DNS OK: kite.zerodha.com -> {ip}")
        except Exception as e:
            debug_msg.append(f"DNS FAIL: {e}")

        try:
            r = requests.get("https://kite.zerodha.com", timeout=10)
            debug_msg.append(f"Requests status: {r.status_code}")
        except Exception as e:
            debug_msg.append(f"Requests FAIL: {e}")
        result["network_check"] = " | ".join(debug_msg)

        # Supabase client
        supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

        # Chrome Options
        chrome_options = Options()
        chrome_options.set_capability("browserName", "chrome")
        chrome_options.binary_location = "/usr/bin/chromium"
        chrome_options.add_argument("--headless")
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-gpu")
        chrome_options.add_argument("--disable-dev-shm-usage")
        chrome_options.add_argument("--disable-software-rasterizer")
        chrome_options.add_argument("--disable-setuid-sandbox")
        chrome_options.add_argument("--dns-prefetch-disable")
        chrome_options.add_argument("--window-size=1920,1080")

        # Try multiple ChromeDriver paths
        chromedriver_paths = [
            "/usr/lib/chromium/chromedriver",  # Primary Chromium location
            "/usr/local/bin/chromedriver",     # Symlink location
            "/usr/bin/chromedriver",           # Alternative location
            os.getenv('CHROMEDRIVER_PATH'),    # Environment variable
            os.getenv('SELENIUM_DRIVER_PATH')  # Selenium environment variable
        ]
        
        driver = None
        chromedriver_path = None
        
        for path in chromedriver_paths:
            if path and os.path.exists(path):
                try:
                    print(f"Trying ChromeDriver at: {path}")
                    service = Service(executable_path=path)
                    driver = webdriver.Chrome(service=service, options=chrome_options)
                    chromedriver_path = path
                    print(f"✅ ChromeDriver created successfully with path: {path}")
                    break
                except Exception as e:
                    print(f"❌ ChromeDriver failed at {path}: {e}")
                    continue
        
        if driver is None:
            print("❌ ChromeDriver not found in any location")
            print("Available ChromeDriver locations:")
            for path in chromedriver_paths:
                if path:
                    print(f"  - {path}: {'✅ EXISTS' if os.path.exists(path) else '❌ NOT FOUND'}")
            result["error"] = "ChromeDriver not found in any location. Please check Dockerfile installation."
            result["success"] = False
            return jsonify(result)
        driver.set_page_load_timeout(60)
        wait = WebDriverWait(driver, 40)

        # Step 1: Go to login
        login_url = f"https://kite.zerodha.com/connect/login?v=3&api_key={API_KEY}"
        driver.get(login_url)

        # Step 2: Username and password
        userid_field = wait.until(EC.presence_of_element_located((By.ID, "userid")))
        userid_field.clear()
        userid_field.send_keys(Z_USERNAME)
        driver.find_element(By.ID, "password").send_keys(Z_PASSWORD)
        driver.find_element(By.XPATH, "//button[@type='submit']").click()

        # Step 3: TOTP page
        try:
            wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "form.twofa-form input#userid")))
            totp_field = driver.find_element(By.CSS_SELECTOR, "form.twofa-form input#userid")
            totp_field.clear()
            totp = pyotp.TOTP(TOTP_SECRET).now()
            totp_field.send_keys(totp)
            driver.find_element(By.CSS_SELECTOR, "form.twofa-form button[type='submit']").click()
        except TimeoutException:
            result["debug_screenshot"] = base64.b64encode(driver.get_screenshot_as_png()).decode()
            result["debug_html"] = driver.page_source
            raise TimeoutException("TOTP form did not load.")

        # Step 4: Wait for redirect with request_token
        wait.until(lambda d: "request_token" in d.current_url)
        redirected_url = driver.current_url
        parsed = urlparse(redirected_url)
        request_token = parse_qs(parsed.query).get("request_token", [None])[0]
        if not request_token:
            raise Exception("Request token not found in redirected URL.")

        # Step 5: Get access token from Kite
        kite = KiteConnect(api_key=API_KEY)
        data = kite.generate_session(request_token, api_secret=API_SECRET)
        access_token = data["access_token"]

        # Step 6: Save to Supabase
        response = supabase.table("api_tokens").upsert({
            "service": "zerodha",
            "access_token": access_token,
            "created_at": datetime.now().isoformat()
        }, on_conflict="service").execute()

        # Final result
        result["success"] = True
        result["access_token"] = access_token
        result["request_token"] = request_token
        result["supabase_response"] = response.data

    except TimeoutException as te:
        result["error"] = f"Timeout: {str(te)}"
    except Exception as e:
        if driver:
            try:
                result["debug_screenshot"] = base64.b64encode(driver.get_screenshot_as_png()).decode()
                result["debug_html"] = driver.page_source
            except:
                pass
        result["error"] = str(e)
    finally:
        if driver:
            driver.quit()

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

def fetch_daily_full(instrument_token, start_date, end_date):
    """
    Fetch daily bars in 100-day chunks to ensure full coverage.
    """
    delta = timedelta(days=100)
    current_start = start_date
    all_bars = []
    while current_start <= end_date:
        current_end = min(current_start + delta, end_date)
        try:
            bars = kite.historical_data(
                instrument_token=instrument_token,
                from_date=current_start,
                to_date=current_end,
                interval='day'
            ) or []
        except Exception as e:
            print(f"Error fetching {current_start} to {current_end}: {e}")
            bars = []
        all_bars.extend(bars)
        current_start = current_end + timedelta(days=1)
    # Deduplicate by date and sort
    unique = {}
    for bar in all_bars:
        dt = bar['date'].date() if hasattr(bar['date'], 'date') \
             else datetime.fromisoformat(str(bar['date']).replace('Z','+00:00')).date()
        unique[dt] = bar
    return [unique[dt] for dt in sorted(unique.keys())]

def extract_last_trading_days(daily_candles, start_date, end_date):
    """
    From a complete daily series, return one candle per calendar month,
    selecting the last available trading day in each month.
    """
    parsed = []
    for candle in daily_candles:
        if hasattr(candle['date'], 'date'):
            dt = candle['date'].date()
        else:
            dt = datetime.fromisoformat(str(candle['date']).replace('Z','+00:00')).date()
        if start_date <= dt <= end_date:
            parsed.append((dt, candle))

    parsed.sort(key=lambda x: x[0])

    last_by_month = {}
    for dt, candle in parsed:
        key = (dt.year, dt.month)
        last_by_month[key] = candle

    return [ last_by_month[ym] for ym in sorted(last_by_month.keys()) ]

@app.route('/api/stocks/<symbol>/historical', methods=['GET'])
def get_stock_historical_data(symbol):
    """Get historical data for a specific stock with custom date range and frequency."""
    # 1. Read & validate query parameters
    start_date_str = request.args.get('start_date')
    end_date_str   = request.args.get('end_date')
    freq_input     = request.args.get('frequency', 'day').lower()

    if not start_date_str or not end_date_str:
        return jsonify({
            "error": "start_date and end_date are required. Format: YYYY-MM-DD"
        }), 400

    freq_map = {
        'day':'day','daily':'day',
        'week':'week','weekly':'week',
        'month':'day','monthly':'day'
    }
    if freq_input not in freq_map:
        return jsonify({
            "error": f"Invalid frequency. Must be one of: {', '.join(freq_map)}"
        }), 400

    # 2. Parse & sanity‐check dates
    try:
        start_date = datetime.strptime(start_date_str, '%Y-%m-%d').date()
        end_date   = datetime.strptime(end_date_str,   '%Y-%m-%d').date()
    except ValueError:
        return jsonify({"error":"Invalid date format. Use YYYY-MM-DD."}), 400

    if start_date > end_date:
        return jsonify({"error":"start_date cannot be after end_date"}), 400
    if end_date > datetime.now().date():
        return jsonify({"error":"end_date cannot be in the future"}), 400

    # 3. Lookup instrument_token
    instruments = get_all_instruments()
    instrument = next((i for i in instruments if i['tradingsymbol'] == symbol.upper()), None)
    if not instrument:
        return jsonify({"error": f"Stock '{symbol}' not found"}), 404

    # 4. Fetch & filter data
    interval = freq_map[freq_input]
    try:
        if freq_input in ('month','monthly'):
            # Fetch full daily series then extract last trading-day of each month
            raw_daily = fetch_daily_full(
                instrument['instrument_token'],
                start_date, end_date
            )
            data = extract_last_trading_days(raw_daily, start_date, end_date)
        else:
            # daily/weekly: fetch directly at requested interval
            raw = kite.historical_data(
                instrument_token=instrument['instrument_token'],
                from_date=start_date,
                to_date=end_date,
                interval=interval
            ) or []
            data = []
            for candle in raw:
                try:
                    if hasattr(candle['date'], 'date'):
                        dt = candle['date'].date()
                    else:
                        date_str = str(candle['date'])
                        if 'GMT' in date_str:
                            dt = parsedate_to_datetime(date_str).date()
                        else:
                            dt = datetime.fromisoformat(date_str.replace('Z', '+00:00')).date()
                    if start_date <= dt <= end_date:
                        data.append(candle)
                except Exception as e:
                    print(f"Error processing candle: {e}")
                    continue
    except Exception as e:
        traceback.print_exc()
        return jsonify({"error":f"Failed to fetch data: {e}"}), 500

    # 5. Convert timestamps to local timezone (IST) with day name
    ist_timezone = pytz.timezone('Asia/Kolkata')
    
    for candle in data:
        try:
            # Parse the original date
            original_date = candle['date']
            
            if isinstance(original_date, str):
                # Handle string format like "Sun, 01 Jan 2023 18:30:00 GMT"
                if 'GMT' in original_date:
                    # Parse GMT date and convert to IST
                    gmt_dt = parsedate_to_datetime(original_date)
                    ist_dt = gmt_dt.astimezone(ist_timezone)
                else:
                    # Handle ISO format
                    gmt_dt = datetime.fromisoformat(original_date.replace('Z', '+00:00'))
                    ist_dt = gmt_dt.astimezone(ist_timezone)
            else:
                # Handle datetime object
                ist_dt = original_date.astimezone(ist_timezone)
            
            # Format with day name, date, time and timezone
            # Format: "Monday, 02 Jan 2023 00:00:00 IST"
            formatted_date = ist_dt.strftime('%A, %d %b %Y %H:%M:%S %Z')
            
            # Update the date field with IST timestamp including day name
            candle['date'] = formatted_date
            
        except Exception as e:
            print(f"Error converting timezone for candle {candle}: {e}")
            # Keep original if conversion fails
            continue

    # 6. Build & return response
    resp = {
        'symbol': instrument['tradingsymbol'],
        'name': instrument.get('name',''),
        'instrument_token': instrument['instrument_token'],
        'start_date': start_date_str,
        'end_date': end_date_str,
        'frequency': freq_input,
        'interval': interval,
        'data_points': len(data),
        'historical_data': data,
        'last_updated': datetime.now(ist_timezone).strftime('%A, %d %b %Y %H:%M:%S %Z'),
        'timezone': 'Asia/Kolkata (IST)'
    }

    if freq_input in ('month','monthly'):
        resp['note'] = ('Monthly data shows the last trading-day of each month '
                        '(or previous trading-day if month-end was a holiday/weekend).')

    if not data:
        resp['debug_info'] = {
            'message': 'No data available for the specified range.',
            'suggestions': [
                'Try a more recent date range.',
                'Ensure dates fall on trading days (not weekends/holidays).',
                'Verify the stock symbol.',
                'Avoid very distant past ranges.'
            ]
        }

    return jsonify(resp)

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
HEARTBEAT_INTERVAL = 20  # seconds

def background_heartbeat():
    while True:
        socketio.emit('heartbeat', {'message': 'ping', 'timestamp': datetime.now().isoformat()})
        time.sleep(HEARTBEAT_INTERVAL)

@socketio.on('ping_from_client')
def on_client_ping():
    emit('pong_from_server', {'message': 'pong', 'timestamp': datetime.now().isoformat()})
    
if __name__ == "__main__":
    print("Starting Zerodha WebSocket streamer...")
    # Start background tasks using SocketIO's method
    socketio.start_background_task(start_kite_ws)
    socketio.start_background_task(background_tick_sender)
    socketio.start_background_task(background_heartbeat)
    socketio.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", 5000))) 