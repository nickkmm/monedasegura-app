#!/bin/sh
# Writes the runtime config read by the app at startup, from env variables set in
# monedasegura-infra/docker-compose.yml. Runs from nginx's /docker-entrypoint.d/.
set -e
cat > /usr/share/nginx/html/config.json <<JSON
{ "apiBaseUrl": "${API_BASE_URL:-http://localhost:8080/api/v1}" }
JSON
