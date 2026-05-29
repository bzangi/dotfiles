#!/usr/bin/env bash
# Wrapper que delega pra macos/defaults.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULTS_SH="$REPO_ROOT/macos/defaults.sh"

if [[ ! -x "$DEFAULTS_SH" ]]; then
  echo "✗ $DEFAULTS_SH não existe ou não é executável" >&2
  exit 1
fi

bash "$DEFAULTS_SH"
