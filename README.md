# caddy-extended

An unofficial custom Caddy image with [caddy-docker-proxy](https://github.com/lucaslorentz/caddy-docker-proxy) and [caddy-l4](https://github.com/mholt/caddy-l4), built with xcaddy.

Docker Hub: https://hub.docker.com/r/knechtd/caddy-extended

## Features
- HTTP proxy configuration using Docker labels
- Layer 4 TCP/UDP routing
- TLS support, including non-HTTP connections
- Multi-platform images for amd64 and arm64

## Configuration
The image starts with `caddy docker-proxy`. See `compose.example.yml` and `Caddyfile.example` for **generic** examples. All example domains and addresses are placeholders, not production settings.

Maintain persistent Caddy data volumes. Grant access to the Docker socket only to trusted services. Require authentication on exposed backends.

## Updates and CI
Renovate proposes changes to Caddy, plugins, and GitHub Actions. Automatic merge is disabled. Pull requests run build and integration tests. Changes to main are tested before Docker Hub publishing. Deployment to production is configured separately using a deployment tool of your choice.

## Publishing setup
Create the Docker Hub repository `knechtd/caddy-extended`, then set the GitHub Actions repository variable `DOCKERHUB_USERNAME` and secret `DOCKERHUB_TOKEN` (token with push permission). Enable the Renovate GitHub App for this repository.

## Tests
```sh
docker build -t caddy-extended:test .
IMAGE=caddy-extended:test bash tests/smoke.sh
```

## License
This repository's additions are MIT licensed. Caddy and the plugins keep their own upstream licenses. This is not an official project or an upstream fork.

## AI disclaimer
Generative AI assisted with creating code, tests, and documentation. Output must be reviewed and independently verified before production use. The project maintainers are responsible for releases and deployment.
