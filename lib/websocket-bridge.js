#!/usr/bin/env node

/**
 * JOHN REESE VPS - WebSocket to SSH Bridge
 * Provides a WebSocket server that bridges connections to SSH
 */

const WebSocket = require('ws');
const net = require('net');
const fs = require('fs');

const PORT = process.env.WS_PORT || 3000;
const SSH_HOST = process.env.SSH_HOST || '127.0.0.1';
const SSH_PORT = process.env.SSH_PORT || 2222;

console.log(`🚀 Starting WebSocket to SSH bridge on port ${PORT}`);
console.log(`🔗 Bridging to SSH at ${SSH_HOST}:${SSH_PORT}`);

const wss = new WebSocket.Server({
    port: PORT,
    perMessageDeflate: false,
});

let connectionCount = 0;

wss.on('connection', function connection(ws, req) {
    connectionCount++;
    const connectionId = connectionCount;
    const clientIP = req.socket.remoteAddress;
    
    console.log(`[${connectionId}] New WebSocket connection from ${clientIP}`);

    // Create SSH connection
    const ssh = net.createConnection(SSH_PORT, SSH_HOST);
    
    // Handle SSH connection
    ssh.on('connect', () => {
        console.log(`[${connectionId}] SSH connection established`);
        
        // Send custom handshake header
        ws.send(JSON.stringify({
            type: 'handshake',
            message: 'HTTP 101 Switching Protocols - KENYAN JOHN REESE PRIME',
            timestamp: new Date().toISOString()
        }));
    });

    ssh.on('data', (data) => {
        if (ws.readyState === WebSocket.OPEN) {
            ws.send(data);
        }
    });

    ssh.on('close', () => {
        console.log(`[${connectionId}] SSH connection closed`);
        if (ws.readyState === WebSocket.OPEN) {
            ws.close();
        }
    });

    ssh.on('error', (err) => {
        console.error(`[${connectionId}] SSH error:`, err.message);
        if (ws.readyState === WebSocket.OPEN) {
            ws.close(1011, 'SSH connection failed');
        }
    });

    // Handle WebSocket messages
    ws.on('message', (data) => {
        if (ssh.writable) {
            ssh.write(data);
        }
    });

    // Handle WebSocket close
    ws.on('close', () => {
        console.log(`[${connectionId}] WebSocket connection closed`);
        if (ssh.writable) {
            ssh.end();
        }
    });

    // Handle WebSocket error
    ws.on('error', (err) => {
        console.error(`[${connectionId}] WebSocket error:`, err.message);
        if (ssh.writable) {
            ssh.end();
        }
    });
});

wss.on('listening', () => {
    console.log(`✅ WebSocket to SSH bridge listening on port ${PORT}`);
    console.log(`🎯 Ready to accept connections`);
});

wss.on('error', (err) => {
    console.error('❌ WebSocket server error:', err.message);
    process.exit(1);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('🛑 Received SIGTERM, shutting down gracefully...');
    wss.close(() => {
        console.log('✅ WebSocket server closed');
        process.exit(0);
    });
});

process.on('SIGINT', () => {
    console.log('🛑 Received SIGINT, shutting down gracefully...');
    wss.close(() => {
        console.log('✅ WebSocket server closed');  
        process.exit(0);
    });
});