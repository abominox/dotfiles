#!/usr/bin/env bash
# searxng-manage.sh - Manage the local SearXNG Podman container for the research agent
set -euo pipefail

CONTAINER_NAME="searxng"
IMAGE="docker.io/searxng/searxng:latest"
PORT="8888"
INTERNAL_PORT="8080"

usage() {
  echo "Usage: $0 {start|stop|status|restart|logs}"
  exit 1
}

start() {
  if podman ps --filter "name=${CONTAINER_NAME}" --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "SearXNG is already running on http://localhost:${PORT}"
    return 0
  fi

  # Remove any stopped container with the same name
  podman rm -f "${CONTAINER_NAME}" 2>/dev/null || true

  echo "Starting SearXNG on http://localhost:${PORT}..."
  podman run -d \
    --name "${CONTAINER_NAME}" \
    --rm \
    -p "${PORT}:${INTERNAL_PORT}" \
    -e "SEARXNG_BASE_URL=http://localhost:${PORT}/" \
    "${IMAGE}"

  # Wait for it to become healthy
  echo -n "Waiting for SearXNG to be ready"
  for i in $(seq 1 15); do
    if curl -sf "http://localhost:${PORT}" >/dev/null 2>&1; then
      echo " ready!"
      return 0
    fi
    echo -n "."
    sleep 1
  done
  echo " timeout (may still be starting)"
}

stop() {
  echo "Stopping SearXNG..."
  podman stop "${CONTAINER_NAME}" 2>/dev/null || echo "Container not running"
}

status() {
  if podman ps --filter "name=${CONTAINER_NAME}" --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "SearXNG is running on http://localhost:${PORT}"
    podman ps --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
  else
    echo "SearXNG is not running"
    return 1
  fi
}

restart() {
  stop
  sleep 1
  start
}

logs() {
  podman logs -f "${CONTAINER_NAME}"
}

case "${1:-}" in
  start)   start ;;
  stop)    stop ;;
  status)  status ;;
  restart) restart ;;
  logs)    logs ;;
  *)       usage ;;
esac
