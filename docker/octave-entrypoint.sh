#!/usr/bin/env bash
# Entrypoint for the IPEM Toolbox Octave container.
set -euo pipefail

IPEM_ROOT="${IPEM_ROOT:-/opt/IPEMToolbox}"
SMOKE_SCRIPT="${IPEM_ROOT}/tests/smoke_test_octave.m"

run_octave() {
  octave --no-gui --quiet --eval "$1"
}

case "${1:-smoke}" in
  smoke)
    echo "Running IPEM Toolbox Octave smoke test..."
    run_octave "run('${SMOKE_SCRIPT}');"
    ;;
  octave)
    shift || true
    exec octave --no-gui "$@"
    ;;
  bash|sh)
    shift || true
    exec bash "$@"
    ;;
  *)
    # Treat remaining args as an Octave --eval expression or script path.
    if [[ -f "$1" ]]; then
      run_octave "run('$1');"
    else
      run_octave "$*"
    fi
    ;;
esac
