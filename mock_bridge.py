import asyncio
import websockets
import json
import os

async def handle_connection(websocket, path):
    print(f"[+] Client connected from {websocket.remote_address}")
    await websocket.send("--- NEMESIS CORE BRIDGE ACTIVE ---")
    await websocket.send("\n[READY] Enter commands to simulate execution.\n")
    
    try:
        async for message in websocket:
            data = json.loads(message)
            if data.get('type') == 'input':
                user_input = data.get('data', '')
                print(f"[*] Received input: {user_input.strip()}")
                
                # Echo back or simulate response
                if user_input.strip():
                    response = f"\r\n[EXECUTING] {user_input.strip()}\r\nResult: SUCCESS\r\n# "
                    await websocket.send(response)
    except websockets.exceptions.ConnectionClosedOK:
        print("[-] Client disconnected")
    except Exception as e:
        print(f"[!] Error: {e}")

async def main():
    print("[*] Starting Mock Bridge on ws://localhost:8080")
    async with websockets.serve(handle_connection, "localhost", 8080):
        await asyncio.Future()  # run forever

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n[*] Bridge stopped.")
