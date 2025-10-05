#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)

# Reuse the shared logging helpers
# shellcheck source=../logging.sh
source "${ROOT_DIR}/logging.sh"

run_step() {
  local label=$1
  shift
  echo "→ ${label}..."
  LOG_STDOUT=false LOG_LEVEL=ERROR "$@"
  check_error "${label} failed — see logs/pi_cluster.log"
  echo "✓ ${label}"
}

rm -f "${ROOT_DIR}/cluster.data"

run_step "generate_data" "${ROOT_DIR}/generate_data.sh"

grep -q '^NODE_COUNT=' "${ROOT_DIR}/cluster.data" \
  || check_error "cluster.data missing NODE_COUNT"
grep -q '^KAFKA_QUORUM_VOTERS=' "${ROOT_DIR}/cluster.data" \
  || check_error "cluster.data missing KAFKA_QUORUM_VOTERS"

run_step "deploy_config (dry run)" "${ROOT_DIR}/deploy_config.sh" --dry-run

echo "✔ Smoke test passed"
