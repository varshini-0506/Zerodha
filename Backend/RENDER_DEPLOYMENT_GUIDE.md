# Zerodha Backend Deployment Guide for Render

This guide explains how to deploy the Zerodha backend to Render with the improved `/api/refresh_zerodha_token` route that uses async job processing.

## 🚀 Quick Start

1. **Connect your GitHub repository to Render**
2. **Create a new Web Service**
3. **Configure the service with these settings:**
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `gunicorn --bind 0.0.0.0:$PORT app:app --workers 2 --threads 2`
   - **Environment**: Docker
4. **Set all required environment variables**
5. **Deploy the service**

## 📋 Required Environment Variables

Set these environment variables in your Render service:

### 🔐 Zerodha Credentials
- `KITE_USERNAME`: Your Zerodha login username
- `KITE_PASSWORD`: Your Zerodha login password  
- `TOTP_SECRET`: Your TOTP secret for 2FA
- `KITE_API_KEY`: Your Zerodha API key
- `KITE_API_SECRET`: Your Zerodha API secret

### 🗄️ Supabase Configuration
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_KEY`: Your Supabase service role key
- `SUPABASE_SERVICE_ROLE_KEY`: Your Supabase service role key (for compatibility)

### 🔧 Optional Variables
- `PORT`: Port number (Render will set this automatically)
- `FINNHUB_API_KEY`: For additional market data
- `FMP_API_KEY`: For financial modeling prep data

## 🗄️ Supabase Table Setup

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

## 🔄 How the New Async Route Works

The `/api/refresh_zerodha_token` route now uses a job-based approach:

### 1. Start Job
```bash
POST /api/refresh_zerodha_token
```

**Response:**
```json
{
  "status": "started",
  "job_id": "uuid-here"
}
```

### 2. Check Job Status
```bash
GET /api/refresh_result/{job_id}
```

**Response:**
```json
{
  "success": true,
  "access_token": "your_access_token",
  "request_token": "your_request_token",
  "started_at": "2024-01-01T10:00:00Z",
  "finished_at": "2024-01-01T10:01:30Z",
  "error": "",
  "network_check": "DNS:123.456.789.0 | HTTP:200"
}
```

## 🧪 Testing the Deployment

### 1. Health Check
```bash
curl https://your-app.onrender.com/health
```

### 2. Test Refresh Token Route
```bash
# Start the job
curl -X POST https://your-app.onrender.com/api/refresh_zerodha_token

# Check result (replace {job_id} with the actual job ID)
curl https://your-app.onrender.com/api/refresh_result/{job_id}
```

### 3. Use the Test Script
```bash
# Set your API URL
export API_BASE_URL=https://your-app.onrender.com

# Run the test
python test_refresh_route.py
```

## 🔧 Troubleshooting

### Common Issues

#### 1. ChromeDriver Not Found
**Symptoms:** Error about ChromeDriver not being found
**Solution:** The Dockerfile includes comprehensive ChromeDriver installation. Check logs for ChromeDriver verification messages.

#### 2. Missing Environment Variables
**Symptoms:** "Missing required envs" error
**Solution:** Ensure all required environment variables are set in Render dashboard.

#### 3. TOTP Secret Invalid
**Symptoms:** "Invalid TOTP secret" error
**Solution:** Check your TOTP secret format and ensure it's correct.

#### 4. Network Connectivity Issues
**Symptoms:** DNS or HTTP failures in network_check
**Solution:** Check if the Render service has internet access and can reach kite.zerodha.com.

#### 5. Job Timeout
**Symptoms:** Job takes too long or times out
**Solution:** 
- Check Render logs for detailed error messages
- Verify Zerodha credentials are correct
- Ensure Supabase connection is working

### Debug Information

The job result includes debug information:
- `debug_screenshot`: Base64 encoded screenshot if TOTP step fails
- `debug_html`: Page source if login fails
- `network_check`: DNS and HTTP connectivity test results

## 📊 Monitoring

### Health Check Endpoint
```bash
GET /health
```
Returns `OK` if the service is running.

### Market Status Endpoint
```bash
GET /api/market_status
```
Returns current market status and active symbols.

## 🔒 Security Notes

- ✅ Never commit environment variables to your repository
- ✅ Use Render's environment variable management
- ✅ The service runs as a non-root user for security
- ✅ All sensitive data is stored in Supabase, not in the application
- ✅ The job-based approach prevents request timeouts

## 🚀 Performance Optimizations

The new async approach provides several benefits:

1. **No Request Timeouts**: Long-running operations don't timeout the HTTP request
2. **Better Error Handling**: Comprehensive error capture and debugging
3. **Retry Capability**: Can implement retry logic for failed jobs
4. **Scalability**: Can handle multiple concurrent refresh operations

## 📝 API Endpoints Summary

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/api/market_status` | GET | Market status |
| `/api/refresh_zerodha_token` | POST | Start refresh job |
| `/api/refresh_result/{job_id}` | GET | Get job result |
| `/api/stocks` | GET | Get all stocks |
| `/api/stocks/{symbol}` | GET | Get stock details |
| `/api/stocks/batch_quotes` | POST | Get batch quotes |

## 🆘 Support

If you encounter issues:

1. Check the Render logs for detailed error messages
2. Verify all environment variables are set correctly
3. Test the health endpoint first
4. Use the test script to diagnose issues
5. Check the debug information in job results

The improved async approach should make the `/api/refresh_zerodha_token` route much more reliable in the deployed Render environment! 