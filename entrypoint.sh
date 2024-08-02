#!/bin/bash

# Set default values for environment variables
BITCOIND_HOST=${BITCOIND_HOST:-"example.b.voltageapp.io"}
BITCOIND_RPC_PORT=${BITCOIND_RPC_PORT:-"8332"}
BITCOIND_ZMQ_PORT=${BITCOIND_ZMQ_PORT:-"28332"}

# Create stunnel configuration
cat <<EOL > /etc/stunnel/stunnel.conf
client = yes
debug = 7
output = /var/log/stunnel.log

[rpc]
accept = 127.0.0.1:$((${BITCOIND_RPC_PORT} - 1))
connect = ${BITCOIND_HOST}:${BITCOIND_RPC_PORT}

[zmq]
accept = 127.0.0.1:$((${BITCOIND_ZMQ_PORT} - 1))
connect = ${BITCOIND_HOST}:${BITCOIND_ZMQ_PORT}
sni = ${BITCOIND_HOST}
EOL

# Create haproxy configuration
cat <<EOL > /etc/haproxy/haproxy.cfg
global
    log stdout format raw local0 debug
    maxconn 4096

defaults
    log global
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend rpc-in
    bind *:${BITCOIND_RPC_PORT}
    mode http
    option httplog
    default_backend rpc-backend

frontend zmq-in
    bind *:${BITCOIND_ZMQ_PORT}
    mode tcp
    option tcplog
    default_backend zmq-backend

backend rpc-backend
    mode http
    http-request set-header Host ${BITCOIND_HOST}
    server stunnel-rpc 127.0.0.1:$((${BITCOIND_RPC_PORT} - 1))

backend zmq-backend
    mode tcp
    server stunnel-zmq 127.0.0.1:$((${BITCOIND_ZMQ_PORT} - 1))
EOL

# Start stunnel and haproxy
stunnel /etc/stunnel/stunnel.conf &
haproxy -f /etc/haproxy/haproxy.cfg -d

