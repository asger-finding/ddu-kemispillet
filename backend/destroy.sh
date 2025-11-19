#!/bin/bash
set -e

readonly SCRIPT_DIR="$(dirname "$(realpath "$0")")"
readonly ENV_FILE="$SCRIPT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo ".env file missing. Copy .env.example and configure it."
    exit 1
fi

# shellcheck disable=SC2046
export $(grep -v '^#' "$ENV_FILE" | xargs)

readonly IDENTIFIER_NETWORK="${IDENTIFIER_NETWORK:-kemispillet-network}"
readonly IDENTIFIER_APACHE_NAME="${IDENTIFIER_APACHE_NAME:-kemispillet-apache}"
readonly IDENTIFIER_MYSQL="${IDENTIFIER_MYSQL:-kemispillet-mysql}"
readonly IDENTIFIER_DB_VOLUME="${IDENTIFIER_DB_VOLUME:-kemispillet-mysql-data}"
readonly IDENTIFIER_ZEROTIER="${IDENTIFIER_ZEROTIER:-kemispillet-zerotier}"
readonly IDENTIFIER_NGINX="${IDENTIFIER_NGINX:-kemispillet-nginx}"

podman stop "$IDENTIFIER_APACHE_NAME" 2>/dev/null || true
podman stop "$IDENTIFIER_MYSQL" 2>/dev/null || true
podman rm -f "$IDENTIFIER_APACHE_NAME" 2>/dev/null || true
podman rm -f "$IDENTIFIER_MYSQL" 2>/dev/null || true

sudo podman stop "$IDENTIFIER_ZEROTIER" 2>/dev/null || true
sudo podman stop "$IDENTIFIER_NGINX" 2>/dev/null || true
sudo podman rm -f "$IDENTIFIER_ZEROTIER" 2>/dev/null || true
sudo podman rm -f "$IDENTIFIER_NGINX" 2>/dev/null || true

podman network rm "$IDENTIFIER_NETWORK" 2>/dev/null || true
podman volume rm "$IDENTIFIER_DB_VOLUME" 2>/dev/null || true
