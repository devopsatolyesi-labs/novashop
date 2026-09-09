#!/usr/bin/env bash
# NovaShop M03 UI starter Compose helper.
# The secure overlay is mandatory for every action.
set -euo pipefail

action="${1:-config}"
shift || true

case "$action" in
  config)
    docker compose \
      -f src/ui/docker-compose.yml \
      -f deploy/compose/starter.secure.yml \
      config
    ;;
  up)
    docker compose -p novashop-m03-starter \
      -f src/ui/docker-compose.yml \
      -f deploy/compose/starter.secure.yml \
      up --build --detach --wait "$@"
    ;;
  down)
    docker compose -p novashop-m03-starter \
      -f src/ui/docker-compose.yml \
      -f deploy/compose/starter.secure.yml \
      down "$@"
    ;;
  *)
    printf 'Usage: %s [config|up|down] [docker compose options]\n' "$0" >&2
    exit 2
    ;;
esac
