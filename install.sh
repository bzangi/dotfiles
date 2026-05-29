#!/usr/bin/env bash
# Bootstrap entry point. Chama scripts/0X-*.sh em ordem.
# Cada sub-script é idempotente — re-rodar install.sh é seguro.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

echo "════════════════════════════════════════════════════════"
echo " Dotfiles bootstrap — iniciando"
echo "════════════════════════════════════════════════════════"

bash scripts/01-prereqs.sh
bash scripts/02-brew.sh
bash scripts/03-shell.sh
bash scripts/04-stow.sh
bash scripts/05-vscode.sh
bash scripts/06-macos.sh

echo ""
echo "════════════════════════════════════════════════════════"
echo " ✓ Bootstrap completo."
echo "   - Rode 'exec zsh' pra entrar no novo shell."
echo "   - Logout/reboot pra defaults globais (key repeat) tomarem efeito."
echo "   - Crie ~/.zshrc.local e ~/.gitconfig.local com configs per-machine."
echo "════════════════════════════════════════════════════════"
