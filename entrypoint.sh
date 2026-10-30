#!/bin/sh
# Entrypoint for the Xray VLESS+WS node on Buildfyio.
# Listens on the platform-injected $PORT (plain WS inside the container);
# the edge terminates TLS. Non-WS requests (health checks) fall back to a
# tiny local HTTP endpoint.
set -eu

PORT="${PORT:-8080}"
WSPATH="${WSPATH:-/ws}"
HEALTH_PORT="${HEALTH_PORT:-18080}"
: "${UUID:?UUID environment variable is required}"

mkdir -p /tmp/xray

cat > /tmp/xray/config.json <<EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "port": ${PORT},
      "listen": "0.0.0.0",
      "protocol": "vless",
      "settings": {
        "clients": [ { "id": "${UUID}", "flow": "" } ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "${WSPATH}" },
        "fallbacks": [
          { "path": "/", "dest": "127.0.0.1:${HEALTH_PORT}" },
          { "path": "/health", "dest": "127.0.0.1:${HEALTH_PORT}" }
        ]
      }
    }
  ],
  "outbounds": [ { "protocol": "freedom", "settings": {} } ]
}
EOF

# Tiny health endpoint (BusyBox httpd) for platform health checks.
busybox httpd -f -p "127.0.0.1:${HEALTH_PORT}" -h /www >/tmp/xray/httpd.log 2>&1 &

exec /app/xray run -c /tmp/xray/config.json
