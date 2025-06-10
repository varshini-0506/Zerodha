from flask import Flask, jsonify
from kiteticker_service import latest_data  # shared dict from WebSocket

app = Flask(__name__)

# Map instrument_token to symbol manually or dynamically
token_to_symbol = {
    408065: "INFY",
}

@app.route('/realtime/<symbol>', methods=['GET'])
def get_realtime_stock(symbol):
    for token, name in token_to_symbol.items():
        if name.upper() == symbol.upper():
            stock_data = latest_data.get(token)
            if stock_data:
                return jsonify(stock_data)
            else:
                return jsonify({"error": "No live data yet"}), 404
    return jsonify({"error": "Invalid symbol"}), 400

if __name__ == '__main__':
    app.run(debug=True)
