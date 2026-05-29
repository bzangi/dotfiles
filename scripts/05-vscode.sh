#!/usr/bin/env bash
# Copia settings.json e keybindings.json do repo pro path do VS Code.
# Extensions sincronizam via Settings Sync (GitHub login) do próprio VS Code.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VSCODE_USER="$HOME/Library/Application Support/Code/User"

if [[ ! -d "$VSCODE_USER" ]]; then
  echo "ℹ VS Code não instalado (path '$VSCODE_USER' não existe). Skip."
  exit 0
fi

# Copia settings.json (sobrescreve)
if [[ -f "$REPO_ROOT/vscode/settings.json" ]]; then
  cp -f "$REPO_ROOT/vscode/settings.json" "$VSCODE_USER/settings.json"
  echo "✓ settings.json"
fi

# Copia keybindings.json se existe
if [[ -f "$REPO_ROOT/vscode/keybindings.json" ]]; then
  cp -f "$REPO_ROOT/vscode/keybindings.json" "$VSCODE_USER/keybindings.json"
  echo "✓ keybindings.json"
fi

echo "ℹ Extensions: faça login com GitHub no VS Code (Settings Sync) pra sincronizar."
