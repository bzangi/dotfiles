#!/usr/bin/env bash
# Garante Xcode CLI tools e Homebrew. Idempotente.
set -euo pipefail

# --- Xcode CLI tools ---
if ! xcode-select -p &>/dev/null; then
  echo "→ Instalando Xcode CLI tools (vai abrir prompt GUI; aguarde terminar)..."
  xcode-select --install
  # Espera o user terminar a instalação (não há flag de wait nativa)
  until xcode-select -p &>/dev/null; do
    sleep 5
  done
fi
echo "✓ Xcode CLI tools OK"

# --- Homebrew ---
if ! command -v brew &>/dev/null; then
  echo "→ Instalando Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Garante que brew está no PATH desta sessão (Apple Silicon path)
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
echo "✓ Homebrew em $(command -v brew)"
