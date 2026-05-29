#!/usr/bin/env bash
# Instala oh-my-zsh + plugins. Idempotente.
set -euo pipefail

# Dependências (standalone-safe): o installer do oh-my-zsh usa curl, plugins usam git.
command -v git  &>/dev/null || { echo "✗ git ausente — rode scripts/01-prereqs.sh primeiro"  >&2; exit 1; }
command -v curl &>/dev/null || { echo "✗ curl ausente — rode scripts/01-prereqs.sh primeiro" >&2; exit 1; }

# --- Oh My Zsh ---
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo "→ Instalando oh-my-zsh..."
  # RUNZSH=no: não troca shell durante install
  # CHSH=no: não roda chsh
  # KEEP_ZSHRC=yes: não sobrescreve .zshrc existente
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi
echo "✓ oh-my-zsh em $HOME/.oh-my-zsh"

# --- Plugins ---
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
PLUGIN_DIR="$ZSH_CUSTOM/plugins"
mkdir -p "$PLUGIN_DIR"

clone_plugin() {
  local name="$1" repo="$2"
  if [[ ! -d "$PLUGIN_DIR/$name" ]]; then
    echo "→ Clonando $name..."
    git clone --depth=1 "$repo" "$PLUGIN_DIR/$name"
  fi
  echo "✓ $name"
}

clone_plugin zsh-completions          https://github.com/zsh-users/zsh-completions
clone_plugin zsh-autosuggestions      https://github.com/zsh-users/zsh-autosuggestions
clone_plugin zsh-syntax-highlighting  https://github.com/zsh-users/zsh-syntax-highlighting
