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
    # Symlink que já aponta pro próprio arquivo do repo: stow -R cuida (não é conflito).
    if [[ -L "$dest" && "$dest" -ef "$src" ]]; then
      continue
    fi

    # Arquivo regular, symlink "estrangeiro" (aponta pra outro lugar), broken symlink,
    # ou diretório no caminho: faz backup pra não abortar o stow com erro cru.
    if [[ -e "$dest" || -L "$dest" ]]; then
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

# -R = restow (delete + create), idempotente em re-runs.
# --no-folding = nunca substitui um diretório por um symlink (tree-folding). Sem isso,
# num Mac limpo onde ~/.config / ~/.claude ainda não existem, o stow linkaria o
# diretório inteiro pro repo, fazendo apps (gh, iterm2, Claude Code) escreverem dentro
# do working tree — poluindo o git status e arriscando commitar segredos.
echo "→ Running stow..."
cd "$STOW_DIR"
stow -R --no-folding -t "$HOME" "${PACKAGES[@]}"

echo "✓ stow concluído"
