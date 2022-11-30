# Copyright (C) 2018-2022 Sebastian Pipping <sebastian@pipping.org>
# Licensed under GNU Affero GPL v3 or later

# NOTE Keep default tag in sync with docker-compose.yml
FROM caddy:2.6.2-alpine

# Install system upgrades
RUN apk update && apk upgrade

# Install build dependencies
RUN apk update && apk add \
        bash \
        coreutils \
        jq \
        libcap \
        libcap-ng-utils \
        shadow \
        python3

# Allow Caddy to bind to :80 and :433 as unprivileged user
RUN setcap cap_net_bind_service=+ep /usr/bin/caddy && \
    filecap /usr/bin/caddy

# Create nobody-like user for caddy
RUN useradd \
        --create-home \
        --home-dir /home/caddy/ \
        --non-unique --uid 65534 --gid 65534 \
        -K MAIL_DIR=/var/empty \
        caddy
RUN chmod 0700 /home/caddy/
ENV HOME=/home/caddy/
ENV XDG_CONFIG_HOME=/home/caddy/config
ENV XDG_DATA_HOME=/home/caddy/data
VOLUME /home/caddy/

# Create directory to mount sites.cfg file
RUN mkdir -p /etc/caddy/ && chown -R 65534:65534 /etc/caddy
COPY --chown=65534:65534 Caddyfile.generate /etc/caddy

# Uninstall direct build dependencies
RUN apk del libcap libcap-ng libcap-ng-utils linux-pam shadow

# Wipe apk cache
RUN rm -fv /var/cache/apk/*

COPY --chown=65534:65534 docker-entrypoint.sh format-caddy-json-access-log.sh configure-and-run-caddy.sh /

# CMD is based on the official Caddy 2.x.x Docker image
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/configure-and-run-caddy.sh"]
