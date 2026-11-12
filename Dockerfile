# syntax=docker/dockerfile:1
ARG CADDY_VERSION=2.11.7
ARG CADDY_DOCKER_PROXY_VERSION=v2.13.1
ARG CADDY_L4_VERSION=v0.1.3

FROM caddy:${CADDY_VERSION}-builder AS builder
ARG CADDY_VERSION
ARG CADDY_DOCKER_PROXY_VERSION
ARG CADDY_L4_VERSION

RUN xcaddy build "v${CADDY_VERSION}" \
    --with "github.com/lucaslorentz/caddy-docker-proxy/v2@${CADDY_DOCKER_PROXY_VERSION}" \
    --with "github.com/mholt/caddy-l4@${CADDY_L4_VERSION}"

FROM caddy:${CADDY_VERSION}-alpine
COPY --from=builder /usr/bin/caddy /usr/bin/caddy

LABEL org.opencontainers.image.source="https://github.com/knecht-d/caddy-extened" \
      org.opencontainers.image.description="Caddy with Docker label proxy and Layer 4 transport"

EXPOSE 80 443 443/udp
CMD ["caddy", "docker-proxy"]
