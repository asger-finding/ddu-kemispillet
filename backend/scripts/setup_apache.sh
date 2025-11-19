#!/bin/bash

WEB_ROOT="$SCRIPT_DIR/php"

echo "Logging stuff"
echo $SCRIPT_DIR
echo $IDENTIFIER_APACHE_NAME
echo $IDENTIFIER_NETWORK
echo $WEB_ROOT
echo "End log stuff"

mkdir -p "$WEB_ROOT"

# Setup Apache
if podman container exists "$IDENTIFIER_APACHE_NAME" && [ "$(podman inspect -f '{{.State.Running}}' "$IDENTIFIER_APACHE_NAME")" == "true" ]; then
  echo "Apache container already running at http://localhost:8080"
else
  if podman container exists "$IDENTIFIER_APACHE_NAME"; then
    echo "Removing stopped Apache container."
    podman rm -f "$IDENTIFIER_APACHE_NAME"
  fi

  echo "Starting Apache container..."
  podman run -d --name "$IDENTIFIER_APACHE_NAME" \
    --network "$IDENTIFIER_NETWORK" \
    -p 8080:80 \
    --privileged \
    -v "$WEB_ROOT":/var/www/html/api:Z \
    docker.io/library/php:8.2-apache \
    sh -c "apt-get update >/dev/null 2>&1 && apt-get install -y default-libmysqlclient-dev >/dev/null 2>&1 && docker-php-ext-install mysqli >/dev/null 2>&1 && mkdir -p /var/www/html && touch /var/www/html/php_errors.log && chown www-data:www-data /var/www/html/php_errors.log && apache2-foreground" >/dev/null

  echo "Apache started."
  echo "PHP available at http://localhost:8080/api/xxx.php"
fi
