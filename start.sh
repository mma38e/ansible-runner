#!/bin/bash
set -euo pipefail

# start.sh — self-bootstrapping Ansible runner
#
# Behavior depends on where it runs:
#   Outside container → spins up the ansible-runner container with this
#                        directory mounted at /runner, then re-executes
#                        this script inside it.
#   Inside container  → runs your Ansible commands directly.
#
# Usage:
#   ./start.sh                  # auto-detect and run
#   EXTRA_VARS="key=val" ./start.sh
#   SSH_KEY=~/.ssh/id_rsa ./start.sh

# ── Configuration ────────────────────────────────────────────────────────────

IMAGE="${ANSIBLE_RUNNER_IMAGE:-mma38e/ansible-runner:latest}"
INVENTORY="${INVENTORY:-inventory/hosts.yml}"
PLAYBOOK="${PLAYBOOK:-site.yml}"
EXTRA_VARS="${EXTRA_VARS:-}"          # e.g. "env=prod version=1.2"
SSH_KEY="${SSH_KEY:-}"                # e.g. ~/.ssh/id_rsa  (mounted read-only)
VAULT_PASS_FILE="${VAULT_PASS_FILE:-}" # e.g. .vault_pass

# ── Outside container: launch docker and re-run this script inside ───────────

if [[ ! -f /.dockerenv ]]; then
    DOCKER_ARGS=(
        run -it --rm
        -v "$(pwd):/runner"
        -w /runner
    )

    # Mount SSH key if provided
    if [[ -n "${SSH_KEY}" ]]; then
        DOCKER_ARGS+=(-v "${SSH_KEY}:/root/.ssh/id_rsa:ro")
    fi

    # Mount vault password file if provided
    if [[ -n "${VAULT_PASS_FILE}" ]]; then
        DOCKER_ARGS+=(-v "$(pwd)/${VAULT_PASS_FILE}:/runner/${VAULT_PASS_FILE}:ro")
    fi

    # Pass through any ANSIBLE_* env vars from the host
    while IFS= read -r var; do
        DOCKER_ARGS+=(-e "$var")
    done < <(env | grep '^ANSIBLE_' || true)

    exec docker "${DOCKER_ARGS[@]}" "${IMAGE}" /runner/start.sh
fi

# ── Inside container: run Ansible ────────────────────────────────────────────

ANSIBLE_ARGS=(-i "${INVENTORY}" "${PLAYBOOK}")

if [[ -n "${EXTRA_VARS}" ]]; then
    ANSIBLE_ARGS+=(-e "${EXTRA_VARS}")
fi

if [[ -n "${VAULT_PASS_FILE}" ]]; then
    ANSIBLE_ARGS+=(--vault-password-file "${VAULT_PASS_FILE}")
fi

exec ansible-playbook "${ANSIBLE_ARGS[@]}"
