#!/usr/bin/env bash
set -euo pipefail

IMAGE="${IMAGE:-caddy-extended:test}"
NETWORK="caddy-extended-ci-$$"
PROXY="caddy-extended-proxy-$$"
BROKER="caddy-extended-broker-$$"
WEB="caddy-extended-web-$$"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cleanup() {
  docker rm -f "$PROXY" "$WEB" "$BROKER" >/dev/null 2>&1 || true
  docker network rm "$NETWORK" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker network create "$NETWORK" >/dev/null
docker run -d --name "$BROKER" --network "$NETWORK" --network-alias mqtt-broker \
  -v "$ROOT/tests/mosquitto.conf:/mosquitto/config/mosquitto.conf:ro" \
  eclipse-mosquitto:2 >/dev/null

docker run -d --name "$WEB" --network "$NETWORK" \
  --label 'caddy=http://:8080' \
  --label 'caddy.reverse_proxy={{upstreams 80}}' \
  nginx:alpine >/dev/null

docker run -d --name "$PROXY" --network "$NETWORK" \
  -p 127.0.0.1::8080 -p 127.0.0.1::8883 \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v "$ROOT/tests/Caddyfile:/etc/caddy/Caddyfile:ro" \
  -e CADDY_DOCKER_CADDYFILE_PATH=/etc/caddy/Caddyfile \
  -e CADDY_INGRESS_NETWORKS="$NETWORK" \
  "$IMAGE" >/dev/null

HTTP_PORT="$(docker port "$PROXY" 8080/tcp | head -1 | awk -F: '{print $NF}')"
MQTT_PORT="$(docker port "$PROXY" 8883/tcp | head -1 | awk -F: '{print $NF}')"
echo "HTTP test on $HTTP_PORT; MQTT TLS test on $MQTT_PORT"

for i in $(seq 1 45); do
  if curl -fsS --max-time 2 "http://127.0.0.1:$HTTP_PORT/" > /tmp/caddy-ci-http-$$; then
    break
  fi
  sleep 2
done
grep -q 'Welcome to nginx' /tmp/caddy-ci-http-$$
rm -f /tmp/caddy-ci-http-$$

python3 - "$MQTT_PORT" <<'PY'
import socket, ssl, sys, time
port = int(sys.argv[1])
context = ssl._create_unverified_context()  # Ephemeral CI CA, never production.
packet = bytes.fromhex("10 13 00 04 4d 51 54 54 04 02 00 3c 00 07 63 69 2d 6d 71 74 74")
last_error = None
for attempt in range(45):
    try:
        with socket.create_connection(("127.0.0.1", port), timeout=2) as tcp:
            with context.wrap_socket(tcp, server_hostname="mqtt.localhost") as s:
                s.settimeout(2)
                s.sendall(packet)
                response = s.recv(4)
                assert response == b"\x20\x02\x00\x00", f"Unexpected MQTT CONNACK: {response!r}"
                assert s.version() is not None
                print("MQTT TLS + upstream CONNACK passed")
                break
    except Exception as exc:
        last_error = exc
        time.sleep(2)
else:
    raise SystemExit(f"MQTT TLS failed: {last_error}")
PY
