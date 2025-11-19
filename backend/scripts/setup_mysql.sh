#!/bin/bash

# Create network
if ! podman network exists "$IDENTIFIER_NETWORK"; then
  echo "Creating podman network: $IDENTIFIER_NETWORK"
  podman network create "$IDENTIFIER_NETWORK"
fi

DB_SQL="$SCRIPT_DIR/provision/Db.sql"

# Setup MySQL
if podman container exists "$IDENTIFIER_MYSQL" && [ "$(podman inspect -f '{{.State.Running}}' "$IDENTIFIER_MYSQL")" == "true" ]; then
  echo "MySQL container already running at localhost:3306"
else
  if ! podman volume exists "$IDENTIFIER_DB_VOLUME"; then
    echo "Creating MySQL volume: $IDENTIFIER_DB_VOLUME"
    podman volume create "$IDENTIFIER_DB_VOLUME"
  fi
  
  if podman container exists "$IDENTIFIER_MYSQL"; then
    echo "Removing stopped MySQL container."
    podman rm -f "$IDENTIFIER_MYSQL"
  fi
  
  echo "Starting MySQL container..."
  podman run -d --name "$IDENTIFIER_MYSQL" \
    --network "$IDENTIFIER_NETWORK" \
    -e MYSQL_ROOT_PASSWORD=SuperSecret \
    -e MYSQL_ROOT_HOST=% \
    -v "$IDENTIFIER_DB_VOLUME":/var/lib/mysql \
    -p 3306:3306 \
    docker.io/library/mysql:latest >/dev/null
  
  echo "Waiting for MySQL to be ready..."
  until podman exec "$IDENTIFIER_MYSQL" mysql -u root -pSuperSecret -e "SELECT 1" >/dev/null 2>&1; do
    sleep 1
  done
  
  echo "Provisioning database from $DB_SQL"
  podman cp "$DB_SQL" "$IDENTIFIER_MYSQL":/tmp/Db.sql
  podman exec "$IDENTIFIER_MYSQL" bash -c "mysql -u root -pSuperSecret -h 127.0.0.1 < /tmp/Db.sql"
  echo "Database provisioned."

  echo "MySQL container running at localhost:3306"
fi
