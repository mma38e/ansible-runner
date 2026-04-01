#!/bin/bash
set -euo pipefail

# AWX/ansible-runner mode: mount your project at /runner/ and set RUNNER_MODE=awx
# Default: interactive bash shell (or pass any command as args)
#
# Usage examples:
#   docker run -it image                          # bash shell
#   docker run -it image ansible --version        # run a single command
#   docker run -e RUNNER_MODE=awx -v $PWD:/runner image  # AWX runner mode

if [[ "${RUNNER_MODE:-}" == "awx" ]]; then
    exec /runner/start.sh
else
    exec "$@"
fi
