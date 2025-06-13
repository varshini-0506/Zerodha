from kiteconnect import KiteTicker, KiteConnect
import threading
import json

API_KEY = "twjr4rle0urwrre6"
API_SECRET = "v17wa8esxo7341tyk2231mj93e1i8je3"
ACCESS_TOKEN = "KfnbuZVMVhMplVtB9TeVQKfYuiblX12x"

kite = KiteConnect(api_key=API_KEY)
kite.set_access_token(ACCESS_TOKEN)

kws = KiteTicker(API_KEY, ACCESS_TOKEN)

# Example token for INFY
subscribed_tokens = [408065]

latest_data = {}

def on_ticks(ws, ticks):
    global latest_data
    for tick in ticks:
        token = tick['instrument_token']
        latest_data[token] = tick
    print("Ticks:", latest_data)

def on_connect(ws, response):
    print("WebSocket Connected")
    ws.subscribe(subscribed_tokens)
    ws.set_mode(ws.MODE_LTP, subscribed_tokens)  # or MODE_FULL

def on_close(ws, code, reason):
    print("WebSocket Closed:", reason)

def start_websocket():
    kws.on_ticks = on_ticks
    kws.on_connect = on_connect
    kws.on_close = on_close
    kws.connect(threaded=True)

# Start WebSocket in background
threading.Thread(target=start_websocket, daemon=True).start()
