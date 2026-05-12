#!/usr/bin/env bash
# =============================================================================
#  MarketSystem deployment script — production
# =============================================================================
#
#  Pulls the latest commit on the target branch, rebuilds the API + client
#  containers, waits for the API healthcheck to come up, and either confirms
#  success or rolls back to the previous image tag.
#
#  Usage:
#     bash deployment/scripts/deploy.sh                 # deploy master
#     bash deployment/scripts/deploy.sh feature-branch  # deploy a branch
#     ROLLBACK=1 bash deployment/scripts/deploy.sh      # restore previous tag
#
#  Pre-reqs on the host:
#    * docker / docker compose plugin
#    * nginx (reverse proxy; config at /etc/nginx/sites-available/strotech.uz.conf)
#    * .env file with all required secrets (see .env.example)
# =============================================================================

set -euo pipefail

BRANCH="${1:-master}"
PROJECT_DIR="${PROJECT_DIR:-/root/MarketSystemNavoi}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"
HEALTH_URL="http://localhost:8080/health"
HEALTH_MAX_ATTEMPTS=30
HEALTH_DELAY_SECONDS=2

red()    { printf '\033[0;31m%s\033[0m\n' "$*"; }
green()  { printf '\033[0;32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[1;33m%s\033[0m\n' "$*"; }

cd "$PROJECT_DIR" || { red "Project dir not found: $PROJECT_DIR"; exit 1; }

# -----------------------------------------------------------------------------
# Sanity checks: required env, docker, .env file with secrets.
# -----------------------------------------------------------------------------
require_cmd() { command -v "$1" >/dev/null 2>&1 || { red "Missing command: $1"; exit 1; }; }
require_cmd docker
require_cmd git
require_cmd curl

# -----------------------------------------------------------------------------
# Rollback path — restore the previous image tag and re-up. Use when a
# fresh build came up unhealthy.
# Runs BEFORE the .env placeholder check: rollback is an emergency recovery
# operation and must not be blocked by an in-progress .env edit.
# -----------------------------------------------------------------------------
if [[ "${ROLLBACK:-0}" == "1" ]]; then
    yellow "Rolling back to previous deployment..."
    if [[ ! -f .last-deploy-commit ]]; then
        red "No previous deploy on record (.last-deploy-commit missing)."
        exit 1
    fi
    if [[ ! -f .env ]]; then
        red ".env file is missing — cannot start rollback target without secrets."
        exit 1
    fi
    git checkout "$(cat .last-deploy-commit)"
    docker compose -f "$COMPOSE_FILE" up -d --build --force-recreate
    green "Rolled back to $(git rev-parse --short HEAD)."
    exit 0
fi

if [[ ! -f .env ]]; then
    red ".env file is missing. Copy .env.example and fill in real secrets first."
    exit 1
fi

# Refuse to deploy if any required secret is still a placeholder.
if grep -E '^[A-Z_]+=REPLACE_ME' .env >/dev/null; then
    red ".env still contains REPLACE_ME placeholders. Aborting."
    grep -nE '^[A-Z_]+=REPLACE_ME' .env || true
    exit 1
fi

# -----------------------------------------------------------------------------
# Pull, record current commit (for rollback), and rebuild.
# -----------------------------------------------------------------------------
echo "Current commit:  $(git rev-parse --short HEAD)"
git fetch origin
git rev-parse HEAD > .last-deploy-commit
yellow "Checking out origin/$BRANCH..."
git checkout "$BRANCH"
git pull --ff-only origin "$BRANCH"
echo "New commit:      $(git rev-parse --short HEAD)"

yellow "Building containers..."
docker compose -f "$COMPOSE_FILE" up -d --build --remove-orphans

# -----------------------------------------------------------------------------
# Wait for the API healthcheck before declaring success.
# -----------------------------------------------------------------------------
yellow "Waiting for API healthcheck ($HEALTH_URL)..."
for ((i=1; i<=HEALTH_MAX_ATTEMPTS; i++)); do
    if curl --fail --silent "$HEALTH_URL" >/dev/null; then
        green "API healthy after ${i} attempts."
        break
    fi
    if (( i == HEALTH_MAX_ATTEMPTS )); then
        red "API failed to become healthy. Showing recent logs:"
        docker compose -f "$COMPOSE_FILE" logs --tail=80 market-system-api || true
        red "Run with ROLLBACK=1 to restore the previous build."
        exit 1
    fi
    sleep "$HEALTH_DELAY_SECONDS"
done

green "Deploy succeeded. Container status:"
docker compose -f "$COMPOSE_FILE" ps

cat <<EOF

Reminders:
  * nginx config lives at /etc/nginx/sites-available/strotech.uz.conf.
    If you changed deployment/nginx/, sync it then 'nginx -t && systemctl reload nginx'.
  * Logs:    docker compose logs -f market-system-api
  * Rollback: ROLLBACK=1 bash deployment/scripts/deploy.sh
EOF
