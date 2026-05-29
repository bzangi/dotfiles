#!/usr/bin/env bash
# Cria symlinks via GNU stow. Antes, faz backup de arquivos regulares
# existentes pra ~/.dotfiles-backup/<timestamp>/.
set -euo pipefail

if ! command -v stow &>/dev/null; then
  echo "✗ stow não instalado — rode scripts/02-brew.sh primeiro" >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STOW_DIR="$REPO_ROOT/stow"
PACKAGES=(zsh git starship claude)
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# Detecta conflitos: arquivos regulares (não-symlinks) onde stow vai criar link
backup_conflicts() {
  local pkg="$1"
  local pkg_dir="$STOW_DIR/$pkg"

  # Lista todos os arquivos do package, calcula path final em $HOME, verifica conflito
  while IFS= read -r -d '' src; do
    local rel="${src#"$pkg_dir"/}"
    local dest="$HOME/$rel"
    if [[ -e "$dest" && ! -L "$dest" ]]; then
      mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
      mv "$dest" "$BACKUP_DIR/$rel"
      echo "  backed up $dest → $BACKUP_DIR/$rel"
    fi
  done < <(find "$pkg_dir" -type f -not -name '.gitkeep' -print0)
}

for pkg in "${PACKAGES[@]}"; do
  echo "→ Processing package: $pkg"
  backup_conflicts "$pkg"
done

if [[ -d "$BACKUP_DIR" ]]; then
  echo "ℹ Backups de arquivos preexistentes em: $BACKUP_DIR"
fi

# -R = restow (delete + create), idempotente em re-runs
echo "→ Running stow..."
cd "$STOW_DIR"
stow -R -t "$HOME" "${PACKAGES[@]}"

echo "✓ stow concluído"
