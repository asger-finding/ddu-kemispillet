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

readonly ZEROTIER_NETWORK_ID="${ZEROTIER_NETWORK_ID:-}"
readonly IDENTIFIER_NETWORK="${IDENTIFIER_NETWORK:-kemispillet-network}"
readonly IDENTIFIER_APACHE_NAME="${IDENTIFIER_APACHE_NAME:-kemispillet-apache}"
readonly IDENTIFIER_MYSQL="${IDENTIFIER_MYSQL:-kemispillet-mysql}"
readonly IDENTIFIER_DB_VOLUME="${IDENTIFIER_DB_VOLUME:-kemispillet-mysql-data}"
readonly IDENTIFIER_ZEROTIER="${IDENTIFIER_ZEROTIER:-kemispillet-zerotier}"
readonly IDENTIFIER_NGINX="${IDENTIFIER_NGINX:-kemispillet-nginx}"

echo "Starting Kemispillet backend..."
echo ""

export IDENTIFIER_NETWORK
export IDENTIFIER_APACHE_NAME
export IDENTIFIER_MYSQL
export IDENTIFIER_DB_VOLUME
export IDENTIFIER_ZEROTIER
export IDENTIFIER_NGINX

source "$SCRIPT_DIR/scripts/setup_mysql.sh"
source "$SCRIPT_DIR/scripts/setup_apache.sh"

if [ -n "$ZEROTIER_NETWORK_ID" ]; then
    sudo ZEROTIER_NETWORK_ID="$ZEROTIER_NETWORK_ID" \
         SCRIPT_DIR="$SCRIPT_DIR" \
         IDENTIFIER_ZEROTIER="$IDENTIFIER_ZEROTIER" \
         IDENTIFIER_NGINX="$IDENTIFIER_NGINX" \
         bash "$SCRIPT_DIR/scripts/setup_zerotier.sh"
else
    echo "ZeroTier skipped (no network ID provided)"
fi
