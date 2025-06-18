import asyncio
import websockets

async def ws_handler(websocket, path):
    print(f"Connected to {path}")
    try:
        async for message in websocket:
            print(f"Received: {message}")
            await websocket.send(f"Echo: {message}")
    except websockets.exceptions.ConnectionClosed:
        print("Client disconnected")

async def main():
    async with websockets.serve(ws_handler, "0.0.0.0", 6789):
        print("WebSocket server running on ws://0.0.0.0:6789")
        await asyncio.Future()

if __name__ == "__main__":
    asyncio.run(main())