#!/usr/bin/env bash
# Aplica o Brewfile na máquina. Idempotente — brew bundle ignora o que já está.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BREWFILE="$REPO_ROOT/Brewfile"

if [[ ! -f "$BREWFILE" ]]; then
  echo "✗ Brewfile não encontrado em $BREWFILE" >&2
  exit 1
fi

if ! command -v brew &>/dev/null; then
  echo "✗ brew não disponível — rode scripts/01-prereqs.sh primeiro" >&2
  exit 1
fi

echo "→ brew update (silencioso)..."
brew update >/dev/null

echo "→ brew bundle install (lê $BREWFILE)..."
brew bundle install --file="$BREWFILE"

echo "✓ brew bundle aplicado"
