# Zerodha Backend API

A Flask-based backend API for Zerodha trading integration with real-time market data, WebSocket support, and automated token recovery.

## Features

- Real-time stock data via Zerodha WebSocket
- Stock search and details
- Market news aggregation
- Wishlist management with Supabase
- Automated Zerodha token recovery using Selenium
- WebSocket support for live price updates

## Docker Setup for Render Deployment

This backend is configured to run on Render with Docker support, specifically for the `/api/recover_zerodha_token` route which requires Chrome and ChromeDriver for Selenium automation.

### Prerequisites

1. **Render Account**: Sign up at [render.com](https://render.com)
2. **Environment Variables**: Set up all required environment variables in Render dashboard

### Required Environment Variables

Set these in your Render dashboard:

```
KITE_API_KEY=your_zerodha_api_key
KITE_API_SECRET=your_zerodha_api_secret
KITE_USERNAME=your_zerodha_username
KITE_PASSWORD=your_zerodha_password
TOTP_SECRET=your_totp_secret
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
FINNHUB_API_KEY=your_finnhub_api_key
FMP_API_KEY=your_fmp_api_key
```

### Deployment Steps

1. **Connect Repository**: Connect your GitHub repository to Render
2. **Create Web Service**: Choose "Web Service" and select your repository
3. **Configure Build Settings**:
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `gunicorn --worker-class gevent --workers 1 --bind 0.0.0.0:$PORT app:app`
4. **Set Environment Variables**: Add all required environment variables
5. **Deploy**: Click "Create Web Service"

### Docker Configuration

The application uses a custom Dockerfile that:

- Installs Google Chrome and ChromeDriver for Selenium automation
- Sets up virtual display (Xvfb) for headless browser operation
- Configures all necessary environment variables
- Runs Chrome tests before starting the Flask application

### API Endpoints

#### Core Endpoints
- `GET /api/stocks` - Get all stocks with pagination
- `GET /api/stocks/popular` - Get popular stocks
- `GET /api/stocks/<symbol>` - Get detailed stock information
- `POST /api/stocks/batch_quotes` - Get quotes for multiple stocks
- `GET /api/search?q=<query>` - Search stocks

#### Authentication & Token Management
- `POST /api/recover_zerodha_token` - **Automated Zerodha token recovery** (requires Chrome/ChromeDriver)

#### Wishlist Management
- `POST /api/wishlist` - Add stock to wishlist
- `GET /api/wishlist/<user_id>` - Get user's wishlist
- `GET /api/wishlist/details/<user_id>` - Get wishlist with full stock details
- `DELETE /api/wishlist` - Remove stock from wishlist

#### Market Data
- `GET /api/market_status` - Get market status
- `GET /api/news` - Get market news
- `GET /api/stock_events/<symbol>` - Get stock events (earnings, dividends, etc.)

#### WebSocket
- WebSocket connection for real-time tick data
- Event: `tick_data` - Real-time stock price updates

### Testing the Deployment

After deployment, test the Chrome setup:

```bash
curl -X POST https://your-render-app.onrender.com/api/recover_zerodha_token
```

### Troubleshooting

#### Chrome/ChromeDriver Issues
If the `/api/recover_zerodha_token` route fails:

1. Check Render logs for Chrome installation errors
2. Verify environment variables are set correctly
3. Ensure the Docker build completed successfully

#### Common Issues
- **Chrome not found**: Check if Chrome binary path is correct
- **ChromeDriver version mismatch**: ChromeDriver is auto-installed to match Chrome version
- **Permission denied**: ChromeDriver should have execute permissions

### Local Development

For local development without Docker:

```bash
# Install dependencies
pip install -r requirements.txt

# Set environment variables
export KITE_API_KEY=your_key
# ... set other variables

# Run the application
python app.py
```

### Security Notes

- Never commit API keys or secrets to version control
- Use environment variables for all sensitive data
- The `/api/recover_zerodha_token` endpoint should be protected in production
- Consider rate limiting for public endpoints

### Performance

- WebSocket connection is limited to popular stocks to avoid hitting Zerodha's 4000 instrument limit
- Chrome automation is optimized for headless operation
- Database queries are cached where appropriate 