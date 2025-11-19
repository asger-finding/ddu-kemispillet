#!/bin/bash

if [ -z "$ZEROTIER_NETWORK_ID" ]; then
    echo "ZeroTier network ID not set."
    echo ""
    echo "To set up ZeroTier:"
    echo "  1. Go to https://my.zerotier.com"
    echo "  2. Create a network (or use an existing network)"
    echo "  3. Copy the Network ID (16-character hex)"
    echo "  4. Set it in .env as ZEROTIER_NETWORK_ID=your_network_id"
    echo ""
    return 0
fi

ZEROTIER_DATA="$SCRIPT_DIR/zerotier-data"
mkdir -p "$ZEROTIER_DATA"

# Setup ZeroTier container
if podman container exists "$IDENTIFIER_ZEROTIER" && [ "$(podman inspect -f '{{.State.Running}}' "$IDENTIFIER_ZEROTIER")" == "true" ]; then
    echo "ZeroTier container already running."
else
    if podman container exists "$IDENTIFIER_ZEROTIER"; then
        echo "Removing stopped ZeroTier container."
        podman rm -f "$IDENTIFIER_ZEROTIER"
    fi
    
    echo "Starting ZeroTier container..."
    podman run -d --name "$IDENTIFIER_ZEROTIER" \
        --network host \
        --cap-add=NET_ADMIN \
        --cap-add=SYS_ADMIN \
        --device=/dev/net/tun \
        -v "$ZEROTIER_DATA":/var/lib/zerotier-one:Z \
        docker.io/zerotier/zerotier:latest \
        $ZEROTIER_NETWORK_ID
    
    echo "ZeroTier started, joining network: $ZEROTIER_NETWORK_ID"
    echo "Waiting for network to initialize..."
    sleep 5
fi

echo "Checking ZeroTier status..."
ZEROTIER_IP=""
for i in {1..30}; do
    echo "Checking for device authorization"
    ZEROTIER_IP=$(podman exec "$IDENTIFIER_ZEROTIER" zerotier-cli listnetworks 2>/dev/null | grep "$ZEROTIER_NETWORK_ID" | awk '{print $9}' | cut -d'/' -f1)

    if [ -n "$ZEROTIER_IP" ] && [ "$ZEROTIER_IP" != "-" ]; then
        break
    fi
    
    if [ $i -eq 1 ]; then
        echo "Waiting for ZeroTier IP assignment..."
        echo "(You may need to authorize this device at https://my.zerotier.com)"
    fi
    
    sleep 2
done

if [ -z "$ZEROTIER_IP" ] || [ "$ZEROTIER_IP" == "-" ]; then
    echo ""
    echo "Failed to get ZeroTier IP address."
    echo ""
    echo "Troubleshooting:"
    echo "  1. Go to https://my.zerotier.com"
    echo "  2. Click on your network"
    echo "  3. Scroll to 'Members' section"
    echo "  4. Find this device and check the 'Auth' checkbox"
    echo "  5. Wait a few seconds and run this script again"
    echo ""
    
    DEVICE_ID=$(podman exec "$IDENTIFIER_ZEROTIER" zerotier-cli info 2>/dev/null | awk '{print $3}')
    if [ -n "$DEVICE_ID" ]; then
        echo "Your ZeroTier Device ID: $DEVICE_ID"
        echo "(Use this to find your device in the dashboard)"
    fi
    echo ""
    return 1
fi

if podman container exists "$IDENTIFIER_NGINX" && [ "$(podman inspect -f '{{.State.Running}}' "$IDENTIFIER_NGINX")" == "true" ]; then
    echo "Nginx proxy already running."
else
    if podman container exists "$IDENTIFIER_NGINX"; then
        echo "Removing stopped Nginx container."
        podman rm -f "$IDENTIFIER_NGINX"
    fi

    NGINX_CONF="$SCRIPT_DIR/nginx.conf"

    echo "Starting Nginx reverse proxy..."
    podman run -d --name "$NGINX_NAME" \
        --network host \
        -v "$NGINX_CONF":/etc/nginx/nginx.conf:Z,ro \
        docker.io/library/nginx:alpine
    
    echo "Nginx proxy started."
fi

echo ""
echo "Players connect to: $ZEROTIER_IP"
echo "  API: http://$ZEROTIER_IP/api/"
echo "  WebSocket: ws://$ZEROTIER_IP/sync"
echo ""

# Save connection info
mkdir -p "$SCRIPT_DIR/zerotier-data"
cat > "$SCRIPT_DIR/zerotier-data/connection_info.txt" << EOF
ZeroTier Connection Info
IP: $ZEROTIER_IP
Network ID: $ZEROTIER_NETWORK_ID
Started: $(date)

Players connect to:
  API: http://$ZEROTIER_IP/api/
  WebSocket: ws://$ZEROTIER_IP/sync
EOF

echo "Connection info saved to: zerotier-data/connection_info.txt"

# Export for other scripts
export ZEROTIER_IP
export ZEROTIER_NETWORK_ID

cleanup() {
    echo ""
    echo "Shutting down ZeroTier and Nginx..."
    podman stop "$IDENTIFIER_NGINX" 2>/dev/null || true
    podman stop "$IDENTIFIER_ZEROTIER" 2>/dev/null || true
    exit 0
}

trap cleanup SIGINT SIGTERM
