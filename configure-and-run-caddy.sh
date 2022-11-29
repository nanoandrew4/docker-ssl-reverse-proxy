#!/bin/bash

cd /etc/caddy
if [ ! -f sites.cfg ]; then
    echo "sites.cfg file not found in /etc/caddy, please mount it as a volume. Exiting..."
    exit 1
fi
./Caddyfile.generate


cd /
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile