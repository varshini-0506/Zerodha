import datetime as dt
from utils.kiteapp import *
from time import sleep

userid="ZFU212"
today= str(dt.date.today())
access_token= f"utils/access_token2025.txt"

with open(access_token, "r") as file:
    token = file.read().strip()

kite = KiteApp("kite", userid, token)
kws = kite.get_kws()

def on_ticks(ws, ticks):
    # Callback to receive ticks.
    print(ticks)
def on_connect(ws, response):
    # Callback on successful connect.
    # Subscribe to a list of instrument_tokens (RELIANCE and ACC here).
    ws.subscribe([738561, 5633])

    # Set RELIANCE to tick in `full` mode.
    ws.set_mode(ws.MODE_FULL, [738561])

def on_close(ws, code, reason):
    # On connection close stop the main loop
    # Reconnection will not happen after executing `ws.stop()`
    ws.stop()

# Assign the callbacks.
kws.on_ticks = on_ticks
kws.on_connect = on_connect
kws.on_close = on_close

# Infinite loop on the main thread. Nothing after this will run.
# You have to use the pre-defined callbacks to manage subscriptions.
kws.connect()