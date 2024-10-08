# TLS reverse proxy for bitcoind clients

Expose bitcoind JSON-RPC and ZeroMQ ports from behind a TLS gateway.

Useful for clients without native support for TLS, like bitcoin-cli.

Automatically configure [stunnel](https://www.stunnel.org/) to expose
[bitcoind](https://bitcoin.org/) JSON-RPC and ZeroMQ ports from behind a TLS
gateway. Uses [haproxy](https://haproxy.org/) to add the `Host` header for RPC
connections, and to open a working TCP channel for ZMQ.

## Usage

### Inputs

Required:
- Set `BITCOIND_HOST` to the remote TLS gateway (in front of the bitcoin node)
- Set `BITCOIND_RPC_PORT` to the JSON-RPC port of the bitcoin node
  - mainnet: `8332` (default)
  - testnet: `18332`
  - signet: 38332 (includes mutinynet)

Optional:
- Set `BITCOIND_ZMQ_PORT` to the ZeroMQ port of the bitcoin node (default `28332`)
- Local port numbers match the remote ports by default. To override these:
  - `BITCOIND_RPC_PORT`
  - `BITCOIND_ZMQ_PORT`
- Adjust `LOG_LEVEL` to increase or decrease verbosity of the stunnel+haproxy output (default: `notice`)
  - Value must be a syslog level name (in order from quiet to noisy):
    - `emerg`, `alert`, `crit`, `err`, `warning`, `notice`, `info`, `debug`
  - Override a specific subsytem with `HAPROXY_LOG_LEVEL` or `STUNNEL_LOG_LEVEL`.
- Adjust `LISTEN_HOST` if you want the proxy to listen on an interface other
  than `127.0.0.1`


### Proxy usage

Open a tunnel to a mainnet node (RPC port `8332`):

```shell
docker build -t tls_proxy .

export BITCOIND_HOST=ugiywxatim.b.staging.voltageapp.io

docker run --name=bitcoind-proxy -d --rm \
  -p 38332:38332 \
  -p 28332:28332 \
  -e BITCOIND_ZMQ_PORT \
  tls_proxy
```


### bitcoin-cli usage

With the proxy running and connected, you can use bitcoin-cli with standard
ports on localhost:

```shell
RPC_USER=exampleuser
RPC_PASS=randompassword
RPC_PORT=8332

bitcoin-cli -rpcconnect=localhost:$RPC_PORT \
  -rpcuser=$RPC_USER -rpcpassword=$RPC_PASS \
  getblockchaininfo
```


### Other RPC client usage

With the proxy running and connected, use your normal RPC connection parameters
except replace the host with `localhost` or an equivalent IP (like `127.0.0.1`)


### ZeroMQ client usage

Point your ZeroMQ client at `localhost:28332` after the proxy connects, and it
will start receiving events.

Try [zmq_sub.py[(https://github.com/bitcoin/bitcoin/blob/master/contrib/zmq/zmq_sub.py)
from the Bitcoin Core `contrib` directory for an end-to-end test:
```shell
$ python3 zmq_sub.py

- HASH TX  (1398633) -
eedd6dfe38c5adc652047db5b1ec16d14f37fbfa400cd5e4b538e8c621ec5d52
- RAW TX (1398633) -
020000000001010000000000000000000000000000000000000000000000000000000000000000ffffffff0403506413feffffff02c817a804000000001600146a8f30e42f81d23c6e24f34c0ecad822b757e4900000000000000000776a24aa21a9ede2f61c3f71d1defd3fa999dfa36953755c690689799962b48bebd836974e8cf94c4fecc7daa24900473044022023c425c0b41277ee049b15377680d96c9a0401aea6edc863c15b2dbf71169ce602201747536b796fe5994ba67b63a7b92099b3134d4620ab4ceb8de45b28312a0f5c01000120000000000000000000000000000000000000000000000000000000000000000000000000
- SEQUENCE (1270883) -
000001b604bd2731ca4bfb4401fcebe401bd3f70ce198d1986a4b03e72d87c86 C None
- HASH BLOCK (3387) -
000001b604bd2731ca4bfb4401fcebe401bd3f70ce198d1986a4b03e72d87c86
- RAW BLOCK HEADER (3387) -
00000020f28c0448707f4ac2c849511c9a9c134a87332cf0209a0ecca963f6bb26010000525dec21c6e838b5e4d50c40fafb374fd116ecb1b57d0452c6adc538fe6dddee08c59966ae77031e48d00900
```


### Mutinynet

Set `RPC_PORT` to the desired port (`38332` for Mutinynet) and adjust
the exposed ports to match:

```shell
docker build -t tls_proxy .

export BITCOIND_HOST=ugiywxatim.b.staging.voltageapp.io
export BITCOIND_RPC_PORT=38332
export BITCOIND_ZMQ_PORT=28332

docker run --name=bitcoind-proxy -d --rm \
  -p 38332:38332 \
  -p 28332:28332 \
  -e BITCOIND_HOST \
  -e BITCOIND_RPC_PORT \
  -e BITCOIND_ZMQ_PORT \
  tls_proxy
```

With the proxy running, you can use bitcoin-cli exactly the same as
[above](#bitcoin-cli-usage) except with `RPC_PORT=38332`.
