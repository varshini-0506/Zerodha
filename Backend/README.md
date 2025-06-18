# Zerodha Stock Tracker Backend

This is the backend server for the Zerodha Stock Tracker Flutter app. It provides APIs to fetch real-time stock data from Zerodha's Kite API.

## Setup Instructions

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Environment Configuration

Create a `.env` file in the Backend directory with the following variables:

```env
# Zerodha API Configuration
KITE_API_KEY=your_api_key_here
KITE_API_SECRET=your_api_secret_here
KITE_ACCESS_TOKEN=your_access_token_here

# Server Configuration
FLASK_ENV=development
FLASK_DEBUG=True
```

### 3. Get Zerodha API Credentials

1. Go to [Zerodha Developers](https://developers.kite.trade/)
2. Create a new application
3. Get your API Key and API Secret
4. Use the `access_token.py` script to generate an access token:

```bash
python access_token.py
```

### 4. Run the Server

```bash
python main.py
```

The server will start on:
- Flask API: http://localhost:5000
- WebSocket: ws://localhost:6789

## API Endpoints

### GET /api/stocks
Get all available stocks with pagination and search.

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 50)
- `search` (optional): Search term for stock name or symbol

### GET /api/stocks/popular
Get list of popular stocks.

### GET /api/stocks/{symbol}
Get detailed information for a specific stock.

### GET /api/quote/{symbol}
Get real-time quote for a specific stock.

### GET /api/search
Search stocks by symbol or name.

**Query Parameters:**
- `q` (required): Search query

### GET /api/market_status
Get current market status.

## WebSocket

The server also provides a WebSocket connection for real-time data:

- **URL**: ws://localhost:6789
- **Data Format**: JSON with tick data and market status

## Features

- Real-time stock data from Zerodha Kite API
- Instrument caching for better performance
- WebSocket support for live updates
- Search and filtering capabilities
- Historical data support
- Error handling and logging

## Troubleshooting

1. **API Key/Secret Issues**: Make sure your Zerodha API credentials are correct
2. **Access Token Expired**: Regenerate access token using `access_token.py`
3. **Connection Issues**: Check if Zerodha servers are accessible
4. **Rate Limiting**: The API has rate limits, implement proper error handling

## Development

- The server uses Flask for the REST API
- WebSocket support for real-time data
- CORS enabled for frontend integration
- Comprehensive error handling
- Logging for debugging 