import logging
from kiteconnect import KiteConnect, KiteTicker

class KiteApp:
    def __init__(self, app_name, user_id, access_token):
        self.api_key = "twjr4rle0urwrre6"         # Replace with your API Key
        self.api_secret = "v17wa8esxo7341tyk2231mj93e1i8je3"   # Replace with your API Secret
        self.access_token = access_token
        self.user_id = user_id

        # Initialize KiteConnect
        self.kite = KiteConnect(api_key=self.api_key)
        self.kite.set_access_token(self.access_token)

        # Initialize KiteTicker
        self.kws = KiteTicker(self.api_key, self.access_token)

        # Optional: Set logging level
        logging.basicConfig(level=logging.DEBUG)

    def get_kws(self):
        return self.kws

    def get_kite(self):
        return self.kite
