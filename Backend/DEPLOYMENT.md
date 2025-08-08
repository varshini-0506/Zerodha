# Zerodha Backend Deployment Guide for Render

This guide explains how to deploy the Zerodha backend to Render with the `/api/refresh_zerodha_token` route working properly.

## Prerequisites

1. A Render account
2. Zerodha API credentials
3. Supabase project with the `api_tokens` table

## Environment Variables Required

Set these environment variables in your Render service:

### Zerodha Credentials
- `KITE_USERNAME`: Your Zerodha login username
- `KITE_PASSWORD`: Your Zerodha login password
- `TOTP_SECRET`: Your TOTP secret for 2FA
- `KITE_API_KEY`: Your Zerodha API key
- `KITE_API_SECRET`: Your Zerodha API secret

### Supabase Configuration
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_KEY`: Your Supabase service role key
- `SUPABASE_SERVICE_ROLE_KEY`: Your Supabase service role key (for compatibility)

### Optional Variables
- `PORT`: Port number (Render will set this automatically)
- `FINNHUB_API_KEY`: For additional market data
- `FMP_API_KEY`: For financial modeling prep data

## Supabase Table Setup

Create a table called `api_tokens` with the following structure:

```sql
CREATE TABLE api_tokens (
  id SERIAL PRIMARY KEY,
  service VARCHAR(50) NOT NULL,
  access_token TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(service)
);
```

## Deployment Steps

1. **Connect your GitHub repository to Render**
2. **Create a new Web Service**
3. **Configure the service:**
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `./start_docker.sh`
   - **Environment**: Docker
4. **Set all required environment variables**
5. **Deploy the service**

## Testing the Deployment

After deployment, test the `/api/refresh_zerodha_token` route:

```bash
curl -X POST https://your-render-app.onrender.com/api/refresh_zerodha_token
```

Expected response:
```json
{
  "success": true,
  "access_token": "your_access_token",
  "request_token": "your_request_token",
  "error": "",
  "supabase_response": {...}
}
```

## Troubleshooting

### Chrome/ChromeDriver Issues
The Dockerfile includes comprehensive Chrome and ChromeDriver installation. If you encounter issues:

1. Check the logs for ChromeDriver verification messages
2. Ensure all environment variables are set correctly
3. Verify the Supabase connection

### Common Error Messages

- **"ChromeDriver not found"**: The Docker image didn't install ChromeDriver properly
- **"Missing required environment variables"**: Set all required environment variables in Render
- **"Invalid TOTP_SECRET"**: Check your TOTP secret format
- **"Request token not found"**: Zerodha login failed, check credentials

## Health Check

The application includes a health check endpoint at `/health` that Render can use to monitor the service.

## API Endpoints

- `POST /api/refresh_zerodha_token`: Refresh Zerodha access token
- `GET /health`: Health check endpoint
- `GET /api/stocks`: Get available stocks
- `GET /api/market_status`: Get market status
- And many more...

## Security Notes

- Never commit environment variables to your repository
- Use Render's environment variable management
- The service runs as a non-root user for security
- All sensitive data is stored in Supabase, not in the application 