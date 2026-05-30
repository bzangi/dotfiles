#!/usr/bin/env bash
# Aponta o iTerm2 pra carregar preferências da pasta do repo (load-only).
# NÃO versiona via symlink do plist (cfprefsd reescreve/ignora silenciosamente) —
# usa o mecanismo nativo "Load preferences from a custom folder". Idempotente.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ITERM_DIR="$REPO_ROOT/iterm2"
DOMAIN="com.googlecode.iterm2"

if [[ ! -f "$ITERM_DIR/$DOMAIN.plist" ]]; then
  echo "✗ $ITERM_DIR/$DOMAIN.plist não encontrado — capture o plist primeiro" >&2
  exit 1
fi

# iTerm2 vem do Brewfile (02-brew). Se não está instalado, não há o que apontar.
if [[ ! -d "/Applications/iTerm.app" ]]; then
  echo "ℹ iTerm2 não instalado (vem do Brewfile via 02-brew). Skip."
  exit 0
fi

# Load-only: o iTerm LÊ as prefs da pasta do repo no launch; NÃO habilitamos
# save-on-quit, então o repo é a fonte da verdade e updates são conscientes
# (edita no iTerm → re-captura o plist pro repo → commit).
defaults write "$DOMAIN" PrefsCustomFolder -string "$ITERM_DIR"
defaults write "$DOMAIN" LoadPrefsFromCustomFolder -bool true

echo "✓ iTerm2 apontado pra $ITERM_DIR (load-only)."
echo "ℹ Toma efeito no próximo launch. Se o iTerm estiver aberto, saia (Cmd-Q) e reabra."
