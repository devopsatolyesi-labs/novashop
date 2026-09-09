#!/usr/bin/env bash
# NovaShop M03 full Compose helper. Requires a local, non-placeholder secret.
set -euo pipefail

action="${1:-config}"
shift || true

if [[ -z "${DB_PASSWORD:-}" ]]; then
  printf 'DB_PASSWORD must be set in the local shell; do not write it to Git.\n' >&2
  exit 2
fi

case "$DB_PASSWORD" in
  '<'*'>'|CHANGE_ME|changeme|example|password)
    printf 'DB_PASSWORD is a placeholder; set a real local value before using full Compose.\n' >&2
    exit 2
    ;;
esac

compose_args=(
  -p novashop-m03-full
  -f src/app/docker-compose.yml
  -f src/app/compose.override.yaml
  -f deploy/compose/full.secure.yml
)

case "$action" in
  config)
    # Validate without printing resolved environment values, which can contain a secret.
    docker compose "${compose_args[@]}" config --quiet
    ;;
  up)
    docker compose "${compose_args[@]}" up --build --detach --wait "$@"
    ;;
  down)
    docker compose "${compose_args[@]}" down "$@"
    ;;
  *)
    printf 'Usage: %s [config|up|down] [docker compose options]\n' "$0" >&2
    exit 2
    ;;
esac
