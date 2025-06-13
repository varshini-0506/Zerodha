from kiteconnect import KiteConnect

api_key = "twjr4rle0urwrre6"
api_secret = "v17wa8esxo7341tyk2231mj93e1i8je3"
request_token = "1vzTXdF3G2itlPDbzM1JuggE9GPye9vX"

kite = KiteConnect(api_key=api_key)

# This will return access_token and other data
data = kite.generate_session(request_token, api_secret=api_secret)

print("Access Token:", data["access_token"])
