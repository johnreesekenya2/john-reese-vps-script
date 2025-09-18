#!/usr/bin/env python3

"""
JOHN REESE VPS - WebSocket to SSH Bridge (Python version)
Provides a WebSocket server that bridges connections to SSH
"""

import asyncio
import websockets
import socket
import json
import logging
import os
import signal
from datetime import datetime

# Configuration
WS_PORT = int(os.getenv('WS_PORT', 3000))
SSH_HOST = os.getenv('SSH_HOST', '127.0.0.1')
SSH_PORT = int(os.getenv('SSH_PORT', 2222))

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

connection_count = 0

async def handle_websocket(websocket, path):
    global connection_count
    connection_count += 1
    conn_id = connection_count
    client_ip = websocket.remote_address[0]
    
    logger.info(f"[{conn_id}] New WebSocket connection from {client_ip}")
    
    try:
        # Create SSH connection
        ssh_reader, ssh_writer = await asyncio.open_connection(SSH_HOST, SSH_PORT)
        logger.info(f"[{conn_id}] SSH connection established")
        
        # Send handshake message
        handshake = {
            'type': 'handshake',
            'message': 'HTTP 101 Switching Protocols - KENYAN JOHN REESE PRIME',
            'timestamp': datetime.now().isoformat()
        }
        await websocket.send(json.dumps(handshake))
        
        # Create tasks for bidirectional communication
        async def ws_to_ssh():
            try:
                async for message in websocket:
                    if isinstance(message, str):
                        # Handle JSON messages (like handshake responses)
                        try:
                            data = json.loads(message)
                            if data.get('type') == 'data':
                                ssh_writer.write(data['payload'].encode())
                        except json.JSONDecodeError:
                            # Treat as raw data
                            ssh_writer.write(message.encode())
                    else:
                        # Binary data
                        ssh_writer.write(message)
                    await ssh_writer.drain()
            except websockets.exceptions.ConnectionClosed:
                logger.info(f"[{conn_id}] WebSocket connection closed by client")
            except Exception as e:
                logger.error(f"[{conn_id}] WebSocket to SSH error: {e}")
            finally:
                ssh_writer.close()
                await ssh_writer.wait_closed()
        
        async def ssh_to_ws():
            try:
                while True:
                    data = await ssh_reader.read(8192)
                    if not data:
                        break
                    await websocket.send(data)
            except websockets.exceptions.ConnectionClosed:
                logger.info(f"[{conn_id}] WebSocket connection closed during SSH read")
            except Exception as e:
                logger.error(f"[{conn_id}] SSH to WebSocket error: {e}")
        
        # Run both directions concurrently
        await asyncio.gather(ws_to_ssh(), ssh_to_ws(), return_exceptions=True)
        
    except Exception as e:
        logger.error(f"[{conn_id}] Connection error: {e}")
    finally:
        logger.info(f"[{conn_id}] Connection closed")

async def main():
    logger.info(f"🚀 Starting WebSocket to SSH bridge on port {WS_PORT}")
    logger.info(f"🔗 Bridging to SSH at {SSH_HOST}:{SSH_PORT}")
    
    # Start WebSocket server
    server = await websockets.serve(
        handle_websocket,
        "0.0.0.0",
        WS_PORT,
        ping_interval=30,
        ping_timeout=10
    )
    
    logger.info(f"✅ WebSocket to SSH bridge listening on port {WS_PORT}")
    logger.info(f"🎯 Ready to accept connections")
    
    # Handle graceful shutdown
    def signal_handler(signum, frame):
        logger.info(f"🛑 Received signal {signum}, shutting down gracefully...")
        server.close()
    
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)
    
    # Keep the server running
    await server.wait_closed()
    logger.info("✅ WebSocket server closed")

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("🛑 Received keyboard interrupt, exiting...")
    except Exception as e:
        logger.error(f"❌ Fatal error: {e}")
        exit(1)