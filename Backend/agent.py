from typing import List, Dict, Any
import os
import requests

from google import genai
from google.genai import types


def get_current_price(symbol: str) -> dict:
    """Get the latest trade/quote fields for a symbol from the Zerodha-like API.

    This function is expected to call `https://zerodha-production-04a6.up.railway.app/api/stocks/{symbol}`
    and normalize the `quote` and related top-level fields into a compact shape.

    Args:
        symbol: Market symbol (e.g., "TCS").

    Returns:
        Dict with keys (all optional depending on provider response):
        - symbol: str
        - exchange: str  # e.g., "NSE"
        - last_price: float  # from quote.last_price
        - last_trade_time: str  # from quote.last_trade_time, original timezone
        - ohlc: Dict[str, float]  # from quote.ohlc: {open, high, low, close}
        - source_url: str  # the URL used for the request
        - raw_quote: Dict[str, Any]  # full provider `quote` object for debugging
    """
    base_url = "https://zerodha-production-04a6.up.railway.app/api/stocks/"
    url = f"{base_url}{symbol}"
    try:
        response = requests.get(url, timeout=15)
        response.raise_for_status()
        payload = response.json()
    except Exception as exc:
        return {
            "symbol": symbol,
            "source_url": url,
            "error": str(exc),
        }

    quote: Dict[str, Any] = payload.get("quote", {}) or {}
    ohlc: Dict[str, Any] = quote.get("ohlc", {}) or {}
    return {
        "symbol": payload.get("symbol", symbol),
        "exchange": payload.get("exchange"),
        "last_price": quote.get("last_price"),
        "last_trade_time": quote.get("last_trade_time"),
        "ohlc": {
            "open": ohlc.get("open"),
            "high": ohlc.get("high"),
            "low": ohlc.get("low"),
            "close": ohlc.get("close"),
        },
        "source_url": url,
        "raw_quote": quote,
    }


def get_historical_data(symbol: str, limit: int = 200) -> dict:
    """Get historical checkpoints (daily OHLCV) for a symbol from the Zerodha-like API.

    This function is expected to call `https://zerodha-production-04a6.up.railway.app/api/stocks/{symbol}`
    and map the `historical_data` array into a normalized OHLCV list.

    Args:
        symbol: Market symbol (e.g., "TCS").
        limit: Maximum number of most recent historical points to return.

    Returns:
        Dict with keys:
        - symbol: str
        - exchange: str  # e.g., "NSE"
        - timezone: str  # e.g., "Asia/Kolkata (IST)"
        - last_updated: str | None  # from provider
        - instrument_token: int | None
        - instrument_type: str | None
        - name: str | None
        - segment: str | None
        - tick_size: float | int | None
        - lot_size: int | None
        - source_url: str  # the URL used for the request
        - historical_data: List[Dict[str, Any]]  # raw provider array
        - data: List[Dict[str, Any]] normalized OHLCV with items:
          - t: str   # original date string from provider (or normalized ISO-8601)
          - o: float # open
          - h: float # high
          - l: float # low
          - c: float # close
          - v: float # volume
    """
    base_url = "https://zerodha-production-04a6.up.railway.app/api/stocks/"
    url = f"{base_url}{symbol}"
    try:
        response = requests.get(url, timeout=20)
        response.raise_for_status()
        payload = response.json()
    except Exception as exc:
        return {
            "symbol": symbol,
            "source_url": url,
            "error": str(exc),
            "data": [],
        }

    hist: List[Dict[str, Any]] = payload.get("historical_data", []) or []
    # Keep original date string to avoid tz parsing issues; implement ISO if desired
    normalized: List[Dict[str, Any]] = []
    for item in hist[-limit:]:
        normalized.append(
            {
                "t": item.get("date"),
                "o": item.get("open"),
                "h": item.get("high"),
                "l": item.get("low"),
                "c": item.get("close"),
                "v": item.get("volume"),
            }
        )

    return {
        "symbol": payload.get("symbol", symbol),
        "exchange": payload.get("exchange"),
        "timezone": payload.get("timezone"),
        "last_updated": payload.get("last_updated"),
        "instrument_token": payload.get("instrument_token"),
        "instrument_type": payload.get("instrument_type"),
        "name": payload.get("name"),
        "segment": payload.get("segment"),
        "tick_size": payload.get("tick_size"),
        "lot_size": payload.get("lot_size"),
        "source_url": url,
        "historical_data": hist[-limit:],
        "data": normalized,
    }

def get_available_stocks():
    """Get a list of available stocks from the Zerodha-like API. 
    the user given query will only have nick names and not the symbol, so before any process starts convert the nick name asked by the user into actual stock symbol
    Args:
       nothing

    Returns:
        Dict with keys:
        - symbols: list
    """
    return{"symbols":[
            "RELIANCE", "TCS", "HDFCBANK", "INFY", "ICICIBANK",
            "HINDUNILVR", "HDFC", "SBIN", "BHARTIARTL", "ITC",
            "KOTAKBANK", "LT", "AXISBANK", "MARUTI", "ASIANPAINT",
            "WIPRO", "HCLTECH", "ULTRACEMCO", "TITAN", "BAJFINANCE",
            "TATAMOTORS", "SUNPHARMA", "POWERGRID", "TECHM", "NTPC",
            "ADANIENT", "ADANIPORTS", "BAJAJFINSV", "BAJAJ-AUTO", "COALINDIA"
        ]}
    

def compute_technical_indicator(
    symbol: str,
    indicator: str = "sma",
    window: int = 14,
    price_type: str = "close",
) -> dict:
    """Compute a technical indicator using the historical data from the Zerodha-like API.

    Implementation should internally call `get_historical_data(symbol)` and compute the
    requested indicator over the returned `data` list.

    Args:
        symbol: Market symbol (e.g., "TCS").
        indicator: Indicator to compute (e.g., "sma", "ema", "rsi").
        window: Lookback window size.
        price_type: Which price to use: "close"|"open"|"high"|"low".

    Returns:
        Dict with keys:
        - symbol: str
        - indicator: str
        - window: int
        - value: float | None  # latest indicator value
        - series_tail: List[float]  # optional short tail of the series for context
        - source: str  # e.g., "zerodha-api"
    """
    # Fetch historical data first
    hist = get_historical_data(symbol=symbol, limit=max(window * 3, window + 50))
    if hist.get("error"):
        return {
            "symbol": symbol,
            "indicator": indicator,
            "window": window,
            "value": None,
            "series_tail": [],
            "source": "zerodha-api",
            "error": hist["error"],
        }

    key_map = {"close": "c", "open": "o", "high": "h", "low": "l"}
    pt = key_map.get(price_type.lower(), "c")
    prices: List[float] = [
        float(point.get(pt)) for point in hist.get("data", []) if isinstance(point.get(pt), (int, float))
    ]

    def sma(values: List[float], n: int) -> List[float]:
        if n <= 0 or len(values) < n:
            return []
        out: List[float] = []
        running = sum(values[:n])
        out.append(running / n)
        for i in range(n, len(values)):
            running += values[i] - values[i - n]
            out.append(running / n)
        return out

    def ema(values: List[float], n: int) -> List[float]:
        if n <= 0 or len(values) < n:
            return []
        k = 2 / (n + 1)
        ema_vals: List[float] = []
        seed = sum(values[:n]) / n
        ema_vals.append(seed)
        for price in values[n:]:
            ema_vals.append(price * k + ema_vals[-1] * (1 - k))
        return ema_vals

    def rsi(values: List[float], n: int) -> List[float]:
        if n <= 0 or len(values) < n + 1:
            return []
        gains: List[float] = []
        losses: List[float] = []
        for i in range(1, len(values)):
            change = values[i] - values[i - 1]
            gains.append(max(change, 0.0))
            losses.append(max(-change, 0.0))
        avg_gain = sum(gains[:n]) / n
        avg_loss = sum(losses[:n]) / n
        rs_list: List[float] = []
        rs_list.append(float("inf") if avg_loss == 0 else avg_gain / avg_loss)
        for i in range(n, len(gains)):
            avg_gain = (avg_gain * (n - 1) + gains[i]) / n
            avg_loss = (avg_loss * (n - 1) + losses[i]) / n
            rs_list.append(float("inf") if avg_loss == 0 else avg_gain / avg_loss)
        return [100 - (100 / (1 + rs)) if rs != float("inf") else 100.0 for rs in rs_list]

    ind = indicator.lower()
    if ind == "sma":
        series = sma(prices, window)
    elif ind == "ema":
        series = ema(prices, window)
    elif ind == "rsi":
        series = rsi(prices, window)
    else:
        series = []

    return {
        "symbol": symbol,
        "indicator": ind,
        "window": window,
        "value": series[-1] if series else None,
        "series_tail": series[-20:],
        "source": "zerodha-api",
    }


def get_order_book(symbol: str, depth: int = 5) -> dict:
    """Get a level-2 order book snapshot if exposed by the Zerodha-like API.

    If the provider exposes `quote.depth.buy` and `quote.depth.sell`, normalize them.

    Args:
        symbol: Market symbol (e.g., "TCS").
        depth: Number of levels per side to return (truncate or pad accordingly).

    Returns:
        Dict with keys:
        - symbol: str
        - source_url: str
        - bids: List[Dict[str, float]]  # [{price, quantity, orders}, ...]
        - asks: List[Dict[str, float]]  # [{price, quantity, orders}, ...]
        - as_of: str  # timestamp if available in provider payload
    """
    base_url = "https://zerodha-production-04a6.up.railway.app/api/stocks/"
    url = f"{base_url}{symbol}"
    try:
        response = requests.get(url, timeout=15)
        response.raise_for_status()
        payload = response.json()
    except Exception as exc:
        return {
            "symbol": symbol,
            "source_url": url,
            "error": str(exc),
        }

    quote: Dict[str, Any] = payload.get("quote", {}) or {}
    depth_obj: Dict[str, Any] = quote.get("depth", {}) or {}
    buys: List[Dict[str, Any]] = depth_obj.get("buy", []) or []
    sells: List[Dict[str, Any]] = depth_obj.get("sell", []) or []

    def norm(side: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        out: List[Dict[str, Any]] = []
        for lvl in side[:depth]:
            out.append(
                {
                    "price": lvl.get("price"),
                    "quantity": lvl.get("quantity"),
                    "orders": lvl.get("orders"),
                }
            )
        return out

    return {
        "symbol": payload.get("symbol", symbol),
        "source_url": url,
        "bids": norm(buys),
        "asks": norm(sells),
        "as_of": quote.get("timestamp"),
    }


def get_news(symbol: str | None = None, limit: int = 25) -> dict:
    """Fetch market news from the Zerodha-like API, with optional symbol filter.

    Endpoint returns a JSON with keys: {"count": int, "news": [ ... ], "timestamp": str}

    Args:
        symbol: Optional symbol to filter articles by presence in title/description.
        limit: Maximum number of articles to return.

    Returns:
        Dict with keys:
        - symbol: str | None
        - source_url: str
        - count: int  # total returned by provider (before filtering)
        - timestamp: str
        - articles: List[Dict[str, Any]] normalized as:
            - title: str
            - description: str
            - url: str
            - source: str
            - published_at: str
    """
    url = "https://zerodha-production-04a6.up.railway.app/api/news"
    try:
        resp = requests.get(url, timeout=20)
        resp.raise_for_status()
        payload = resp.json()
    except Exception as exc:
        return {
            "symbol": symbol,
            "source_url": url,
            "error": str(exc),
            "articles": [],
        }

    articles: List[Dict[str, Any]] = payload.get("news", []) or []
    normalized: List[Dict[str, Any]] = []
    sym = (symbol or "").strip().lower()

    for item in articles:
        title = (item.get("title") or "")
        desc = (item.get("description") or "")
        if sym:
            hay = f"{title} {desc}".lower()
            if sym not in hay:
                continue
        normalized.append(
            {
                "title": title,
                "description": desc,
                "url": item.get("link"),
                "source": item.get("source"),
                "published_at": item.get("pubDate"),
            }
        )
        if len(normalized) >= limit:
            break

    return {
        "symbol": symbol,
        "source_url": url,
        "count": payload.get("count"),
        "timestamp": payload.get("timestamp"),
        "articles": normalized,
    }





# Configure the model tool registry only (no execution here)
config = types.GenerateContentConfig(
    tools=[
        get_current_price,
        get_historical_data,
        get_news,
        compute_technical_indicator,
        get_order_book,
        get_available_stocks,
    ]
)


def answer(audio_path: str, prompt: str = "user have asked a question respond them, the user might ask very vague question , so respond them with the data you have access to") -> str:
    """Upload the provided audio file and generate a response using the configured tools.

    Args:
        audio_path: Filesystem path to the audio file received from the HTTP client.
        prompt: Optional user/system instruction to accompany the audio.

    Returns:
        The model's text response.
    """
    client = genai.Client(api_key="AIzaSyBVQZ6bw5n7dACioMacuiURsZd1lefge_U")
    if not os.path.exists(audio_path) or os.path.getsize(audio_path) == 0:
        raise FileNotFoundError(f"Audio file not found or empty: {audio_path}")
    myfile = client.files.upload(file=audio_path)
    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=[prompt, myfile],
        config=config,
    )
    return response.text