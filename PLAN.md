# Dotfiles Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a dotfiles repo at `~/Desktop/personal/dotfiles/` that captures current Mac configs and bootstraps a fresh Mac via `./install.sh`.

**Architecture:** GNU Stow handles symlinks for `$HOME`-rooted files (zsh, git, starship, claude). Numbered bash scripts (`scripts/0X-*.sh`) handle install of brew, oh-my-zsh, plugins, vscode, and macOS defaults. `install.sh` orchestrates them in order. Each sub-script is idempotent and runnable standalone.

**Tech Stack:** bash, GNU stow, Homebrew (Brewfile + brew bundle), oh-my-zsh, Starship, defaults(1).

**Reference docs:**
- `SPEC.md` — design decisions, scope, architecture
- `CLAUDE.md` — operational playbook (post-implementation maintenance)

---

## Phase 1 — Foundation

### Task 1: Directory skeleton

**Files:**
- Create: `~/Desktop/personal/dotfiles/stow/`
- Create: `~/Desktop/personal/dotfiles/scripts/`
- Create: `~/Desktop/personal/dotfiles/macos/`
- Create: `~/Desktop/personal/dotfiles/vscode/`

- [ ] **Step 1: Create the directory tree**

```bash
cd ~/Desktop/personal/dotfiles
mkdir -p stow/{zsh,git,starship/.config,claude/.claude}
mkdir -p scripts macos vscode
```

- [ ] **Step 2: Verify**

```bash
tree -L 3 -a ~/Desktop/personal/dotfiles | head -20
```

Expected: shows all created dirs plus the existing `.git`, `SPEC.md`, `CLAUDE.md`.

- [ ] **Step 3: Commit**

```bash
# Stow won't pick up empty dirs; add .gitkeep placeholders for now
touch stow/zsh/.gitkeep stow/git/.gitkeep stow/starship/.config/.gitkeep stow/claude/.claude/.gitkeep
touch scripts/.gitkeep macos/.gitkeep vscode/.gitkeep
git add -A
git commit -m "scaffold: create dotfiles directory structure"
```

---

### Task 2: .gitignore

**Files:**
- Create: `~/Desktop/personal/dotfiles/.gitignore`

- [ ] **Step 1: Write the file**

```gitignore
# Local overrides — per-machine, NEVER commit
**/.local
.zshrc.local
.gitconfig.local
Brewfile.local
.claude/CLAUDE.local.md

# Guard-rail: credentials that should never be here
*.pem
*.key
id_rsa*
id_ed25519*
.env
.env.*
!.env.example

# OS / editor cruft
.DS_Store
*.swp
*.swo
.idea/

# Backup dirs created by 04-stow.sh
.dotfiles-backup/
```

- [ ] **Step 2: Verify it parses**

```bash
cd ~/Desktop/personal/dotfiles
git check-ignore -v -- .DS_Store .zshrc.local nonexistent
```

Expected: `.DS_Store` and `.zshrc.local` show as ignored, `nonexistent` does not match.

- [ ] **Step 3: Commit**

```bash
git add .gitignore
git commit -m "scaffold: add .gitignore for local files and secrets"
```

---

## Phase 2 — Capture current configs

### Task 3: Capture .zshrc

**Files:**
- Create: `~/Desktop/personal/dotfiles/stow/zsh/.zshrc` (from `~/.zshrc`)

- [ ] **Step 1: Copy current .zshrc into the repo**

```bash
cp ~/.zshrc ~/Desktop/personal/dotfiles/stow/zsh/.zshrc
```

- [ ] **Step 2: Verify byte-identical**

```bash
diff -q ~/.zshrc ~/Desktop/personal/dotfiles/stow/zsh/.zshrc
```

Expected: no output (files identical).

- [ ] **Step 3: Remove placeholder**

```bash
rm ~/Desktop/personal/dotfiles/stow/zsh/.gitkeep
```

- [ ] **Step 4: Commit**

```bash
cd ~/Desktop/personal/dotfiles
git add stow/zsh/.zshrc
git rm stow/zsh/.gitkeep
git commit -m "capture: snapshot of ~/.zshrc"
```

---

### Task 4: Capture .gitconfig + .gitignore_global

**Files:**
- Create: `~/Desktop/personal/dotfiles/stow/git/.gitconfig`
- Create: `~/Desktop/personal/dotfiles/stow/git/.gitignore_global` (if exists)

- [ ] **Step 1: Copy .gitconfig**

```bash
cp ~/.gitconfig ~/Desktop/personal/dotfiles/stow/git/.gitconfig
```

- [ ] **Step 2: Copy .gitignore_global if exists**

```bash
[[ -f ~/.gitignore_global ]] && cp ~/.gitignore_global ~/Desktop/personal/dotfiles/stow/git/.gitignore_global
ls ~/Desktop/personal/dotfiles/stow/git/
```

- [ ] **Step 3: Verify**

```bash
diff -q ~/.gitconfig ~/Desktop/personal/dotfiles/stow/git/.gitconfig
```

Expected: no output.

- [ ] **Step 4: Commit**

```bash
cd ~/Desktop/personal/dotfiles
rm stow/git/.gitkeep
git add stow/git/
git rm stow/git/.gitkeep 2>/dev/null || true
git commit -m "capture: snapshot of ~/.gitconfig"
```

---

### Task 5: Capture starship TOMLs

**Files:**
- Create: `~/Desktop/personal/dotfiles/stow/starship/.config/starship-light.toml`
- Create: `~/Desktop/personal/dotfiles/stow/starship/.config/starship-dark.toml`

- [ ] **Step 1: Copy both TOMLs**

```bash
cp ~/.config/starship-light.toml ~/Desktop/personal/dotfiles/stow/starship/.config/
cp ~/.config/starship-dark.toml  ~/Desktop/personal/dotfiles/stow/starship/.config/
```

- [ ] **Step 2: Verify bytes preserved (Nerd Font icons are UTF-8 PUA chars)**

```bash
for icon_bytes in "ef81bb" "ee82a0" "eeb48d" "f3b0b88f" "ef8687"; do
  count_orig=$(xxd -p ~/.config/starship-light.toml | tr -d '\n' | grep -oc "$icon_bytes")
  count_copy=$(xxd -p ~/Desktop/personal/dotfiles/stow/starship/.config/starship-light.toml | tr -d '\n' | grep -oc "$icon_bytes")
  echo "  $icon_bytes: orig=$count_orig  copy=$count_copy"
done
```

Expected: each row shows `orig=N copy=N` with matching counts (folder, git, node, aws, archive icons present).

- [ ] **Step 3: Commit**

```bash
cd ~/Desktop/personal/dotfiles
rm stow/starship/.config/.gitkeep
git add stow/starship/
git rm stow/starship/.config/.gitkeep 2>/dev/null || true
git commit -m "capture: snapshot of starship-{light,dark}.toml"
```

---

### Task 6: Capture ~/.claude/ subset

**Files:**
- Create: `~/Desktop/personal/dotfiles/stow/claude/.claude/CLAUDE.md` (from `~/.claude/CLAUDE.md`)
- Create: `~/Desktop/personal/dotfiles/stow/claude/.claude/settings.json` (from `~/.claude/settings.json`)
- Create: `~/Desktop/personal/dotfiles/stow/claude/.claude/memory/` (full subtree from `~/.claude/projects/-Users-brunoz--oh-my-zsh/memory/` if exists)

- [ ] **Step 1: Inspect what's in ~/.claude/**

```bash
ls -la ~/.claude/
```

Expected: shows `CLAUDE.md`, `settings.json`, and possibly subdirs like `projects/`, `plugins/`. Note which are relevant to version.

- [ ] **Step 2: Copy what makes sense**

```bash
DEST=~/Desktop/personal/dotfiles/stow/claude/.claude

[[ -f ~/.claude/CLAUDE.md ]]      && cp ~/.claude/CLAUDE.md     "$DEST/CLAUDE.md"
[[ -f ~/.claude/settings.json ]]  && cp ~/.claude/settings.json "$DEST/settings.json"

# Memory is per-project; the "global memory" lives in this path pattern
MEMORY_SRC=~/.claude/projects/-Users-brunoz--oh-my-zsh/memory
if [[ -d "$MEMORY_SRC" ]]; then
  mkdir -p "$DEST/projects/-Users-brunoz--oh-my-zsh"
  cp -R "$MEMORY_SRC" "$DEST/projects/-Users-brunoz--oh-my-zsh/"
fi

ls -R "$DEST"
```

Expected: lists `CLAUDE.md`, `settings.json`, and `projects/.../memory/MEMORY.md` plus any other memory files if they exist.

- [ ] **Step 3: Verify no segredos no settings.json**

```bash
# Check for accidentally committed tokens/keys
grep -iE 'api[_-]?key|token|secret|password|bearer' "$DEST/settings.json" || echo "OK — no obvious secrets"
```

Expected: "OK — no obvious secrets". If anything found, **stop** and review manually.

- [ ] **Step 4: Commit**

```bash
cd ~/Desktop/personal/dotfiles
rm stow/claude/.claude/.gitkeep
git add stow/claude/
git rm stow/claude/.claude/.gitkeep 2>/dev/null || true
git commit -m "capture: snapshot of ~/.claude/ configs"
```

---

### Task 7: Generate Brewfile

**Files:**
- Create: `~/Desktop/personal/dotfiles/Brewfile`

- [ ] **Step 1: Generate from current install**

```bash
cd ~/Desktop/personal/dotfiles
brew bundle dump --file=Brewfile --force
wc -l Brewfile
```

Expected: ~150-200 lines covering formulas + casks + taps.

- [ ] **Step 2: Verify includes critical items**

```bash
grep -E '^(brew|cask) "(coreutils|stow|git|starship|font-jetbrains-mono-nerd-font|visual-studio-code)"' Brewfile
```

Expected: every line listed (or note if any are missing — install them now if so).

- [ ] **Step 3: Commit**

```bash
git add Brewfile
git commit -m "capture: Brewfile from current brew bundle"
```

---

### Task 8: Capture VS Code settings + keybindings

**Files:**
- Create: `~/Desktop/personal/dotfiles/vscode/settings.json`
- Create: `~/Desktop/personal/dotfiles/vscode/keybindings.json` (if exists)

- [ ] **Step 1: Copy**

```bash
VSCODE_USER="$HOME/Library/Application Support/Code/User"
cp "$VSCODE_USER/settings.json"     ~/Desktop/personal/dotfiles/vscode/settings.json

[[ -f "$VSCODE_USER/keybindings.json" ]] && \
  cp "$VSCODE_USER/keybindings.json" ~/Desktop/personal/dotfiles/vscode/keybindings.json
```

- [ ] **Step 2: Verify**

```bash
ls -la ~/Desktop/personal/dotfiles/vscode/
```

Expected: `settings.json` present, `keybindings.json` if it exists.

- [ ] **Step 3: Commit**

```bash
cd ~/Desktop/personal/dotfiles
rm vscode/.gitkeep
git add vscode/
git rm vscode/.gitkeep 2>/dev/null || true
git commit -m "capture: VS Code settings + keybindings"
```

---

## Phase 3 — Sub-scripts

### Task 9: macos/defaults.sh

**Files:**
- Create: `~/Desktop/personal/dotfiles/macos/defaults.sh`

- [ ] **Step 1: Write the script**

```bash
cat > ~/Desktop/personal/dotfiles/macos/defaults.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Aplicado pelo scripts/06-macos.sh ou rodado standalone.
# 19 defaults capturados da máquina atual em 2026-05-29.

# ================================ KEYBOARD ================================
defaults write -g ApplePressAndHoldEnabled -bool false
defaults write -g InitialKeyRepeat -int 15
defaults write -g KeyRepeat -int 2
defaults write -g NSAutomaticCapitalizationEnabled -bool false
defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write -g NSAutomaticDashSubstitutionEnabled -bool false
defaults write -g NSAutomaticQuoteSubstitutionEnabled -bool false

# ================================ FINDER =================================
defaults write -g AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true

# ============================== TRACKPAD =================================
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# ================================ DOCK ===================================
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 46
defaults write com.apple.dock magnification -bool true
defaults write com.apple.dock show-recents -bool false

# =============================== APPEARANCE ==============================
defaults write -g AppleShowScrollBars -string "Always"
defaults write -g AppleHighlightColor -string "0.698039 0.843137 1.000000 Blue"

# =============================== HOT CORNERS =============================
# Action codes: 0=none, 2=mission-control, 4=desktop, 5=screen-saver,
# 10=display-sleep, 11=launchpad, 12=notif-center, 13=lock-screen, 14=quick-note
defaults write com.apple.dock wvous-br-corner -int 14         # bottom-right = Quick Note

# ============================ SCREENCAPTURE ==============================
defaults write com.apple.screencapture type -string "jpg"

# ================== Restart de apps afetados (idempotente) ===============
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true

echo "✓ macos/defaults.sh aplicado. Logout/reboot pra mudanças globais (key repeat) tomarem efeito completo."
EOF
chmod +x ~/Desktop/personal/dotfiles/macos/defaults.sh
```

- [ ] **Step 2: Lint with shellcheck**

```bash
shellcheck ~/Desktop/personal/dotfiles/macos/defaults.sh
```

Expected: no errors. If shellcheck not installed: `brew install shellcheck` first.

- [ ] **Step 3: Dry test (script should run idempotently against current machine)**

```bash
bash ~/Desktop/personal/dotfiles/macos/defaults.sh
```

Expected: ends with "✓ macos/defaults.sh aplicado." No errors. Dock/Finder reiniciam (você verá um flicker breve).

- [ ] **Step 4: Commit**

```bash
cd ~/Desktop/personal/dotfiles
rm macos/.gitkeep 2>/dev/null
git add macos/defaults.sh
git rm macos/.gitkeep 2>/dev/null || true
git commit -m "feat(macos): defaults.sh with 19 captured customizations"
```

---

### Task 10: scripts/01-prereqs.sh

**Files:**
- Create: `~/Desktop/personal/dotfiles/scripts/01-prereqs.sh`

- [ ] **Step 1: Write the script**

```bash
cat > ~/Desktop/personal/dotfiles/scripts/01-prereqs.sh <<'EOF'
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
EOF
chmod +x ~/Desktop/personal/dotfiles/scripts/01-prereqs.sh
```

- [ ] **Step 2: Lint**

```bash
shellcheck ~/Desktop/personal/dotfiles/scripts/01-prereqs.sh
```

Expected: no errors.

- [ ] **Step 3: Dry test (em máquina com brew já instalado deve ser no-op)**

```bash
bash ~/Desktop/personal/dotfiles/scripts/01-prereqs.sh
```

Expected:
```
✓ Xcode CLI tools OK
✓ Homebrew em /opt/homebrew/bin/brew
```

- [ ] **Step 4: Commit**

```bash
cd ~/Desktop/personal/dotfiles
git add scripts/01-prereqs.sh
git commit -m "feat(scripts): 01-prereqs.sh — xcode CLI + homebrew"
```

---

### Task 11: scripts/02-brew.sh

**Files:**
- Create: `~/Desktop/personal/dotfiles/scripts/02-brew.sh`

- [ ] **Step 1: Write the script**

```bash
cat > ~/Desktop/personal/dotfiles/scripts/02-brew.sh <<'EOF'
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
EOF
chmod +x ~/Desktop/personal/dotfiles/scripts/02-brew.sh
```

- [ ] **Step 2: Lint + dry test**

```bash
shellcheck ~/Desktop/personal/dotfiles/scripts/02-brew.sh
bash ~/Desktop/personal/dotfiles/scripts/02-brew.sh
```

Expected: no shellcheck errors; brew bundle install completes (idempotent — todos os formulas já estão).

- [ ] **Step 3: Commit**

```bash
cd ~/Desktop/personal/dotfiles
git add scripts/02-brew.sh
git commit -m "feat(scripts): 02-brew.sh — brew bundle install"
```

---

### Task 12: scripts/03-shell.sh

**Files:**
- Create: `~/Desktop/personal/dotfiles/scripts/03-shell.sh`

- [ ] **Step 1: Write the script**

```bash
cat > ~/Desktop/personal/dotfiles/scripts/03-shell.sh <<'EOF'
#!/usr/bin/env bash
# Instala oh-my-zsh + plugins. Idempotente.
set -euo pipefail

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
EOF
chmod +x ~/Desktop/personal/dotfiles/scripts/03-shell.sh
```

- [ ] **Step 2: Lint + dry test**

```bash
shellcheck ~/Desktop/personal/dotfiles/scripts/03-shell.sh
bash ~/Desktop/personal/dotfiles/scripts/03-shell.sh
```

Expected: oh-my-zsh detectado (no-op) + 3 plugins detectados (no-op se já clonados).

- [ ] **Step 3: Commit**

```bash
cd ~/Desktop/personal/dotfiles
git add scripts/03-shell.sh
git commit -m "feat(scripts): 03-shell.sh — oh-my-zsh + plugins"
```

---

### Task 13: scripts/04-stow.sh

**Files:**
- Create: `~/Desktop/personal/dotfiles/scripts/04-stow.sh`

- [ ] **Step 1: Write the script**

```bash
cat > ~/Desktop/personal/dotfiles/scripts/04-stow.sh <<'EOF'
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
    local rel="${src#$pkg_dir/}"
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
EOF
chmod +x ~/Desktop/personal/dotfiles/scripts/04-stow.sh
```

- [ ] **Step 2: Lint**

```bash
shellcheck ~/Desktop/personal/dotfiles/scripts/04-stow.sh
```

Expected: no errors.

- [ ] **Step 3: Dry run (em máquina atual, arquivos do $HOME serão movidos pro backup)**

⚠ **Antes de rodar:** confirma com o usuário. Esse passo move `~/.zshrc`, `~/.gitconfig`, etc pra um backup e cria symlinks. É reversível (mv de volta).

```bash
bash ~/Desktop/personal/dotfiles/scripts/04-stow.sh
```

Expected:
```
→ Processing package: zsh
  backed up /Users/brunoz/.zshrc → /Users/brunoz/.dotfiles-backup/.../.zshrc
→ Processing package: git
  backed up /Users/brunoz/.gitconfig → ...
→ Processing package: starship
  backed up /Users/brunoz/.config/starship-light.toml → ...
  backed up /Users/brunoz/.config/starship-dark.toml → ...
→ Processing package: claude
  backed up /Users/brunoz/.claude/CLAUDE.md → ...
  ...
→ Running stow...
✓ stow concluído
```

- [ ] **Step 4: Verify symlinks foram criados**

```bash
ls -la ~/.zshrc ~/.gitconfig ~/.config/starship-light.toml | grep -- '->'
```

Expected: 3 linhas mostrando `->` apontando pro repo.

- [ ] **Step 5: Verify shell still works (sanity)**

```bash
zsh -i -c 'theme; echo "OK"'
```

Expected: imprime "tema atual: light" e "OK" sem erros.

- [ ] **Step 6: Commit**

```bash
cd ~/Desktop/personal/dotfiles
git add scripts/04-stow.sh
git commit -m "feat(scripts): 04-stow.sh — symlinks com backup de conflitos"
```

---

### Task 14: scripts/05-vscode.sh

**Files:**
- Create: `~/Desktop/personal/dotfiles/scripts/05-vscode.sh`

- [ ] **Step 1: Write the script**

```bash
cat > ~/Desktop/personal/dotfiles/scripts/05-vscode.sh <<'EOF'
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
  cp "$REPO_ROOT/vscode/settings.json" "$VSCODE_USER/settings.json"
  echo "✓ settings.json"
fi

# Copia keybindings.json se existe
if [[ -f "$REPO_ROOT/vscode/keybindings.json" ]]; then
  cp "$REPO_ROOT/vscode/keybindings.json" "$VSCODE_USER/keybindings.json"
  echo "✓ keybindings.json"
fi

echo "ℹ Extensions: faça login com GitHub no VS Code (Settings Sync) pra sincronizar."
EOF
chmod +x ~/Desktop/personal/dotfiles/scripts/05-vscode.sh
```

- [ ] **Step 2: Lint + dry test**

```bash
shellcheck ~/Desktop/personal/dotfiles/scripts/05-vscode.sh
bash ~/Desktop/personal/dotfiles/scripts/05-vscode.sh
```

Expected: imprime "✓ settings.json" + "✓ keybindings.json" se existir. Sem erros.

- [ ] **Step 3: Commit**

```bash
cd ~/Desktop/personal/dotfiles
git add scripts/05-vscode.sh
git commit -m "feat(scripts): 05-vscode.sh — copia settings + keybindings"
```

---

### Task 15: scripts/06-macos.sh

**Files:**
- Create: `~/Desktop/personal/dotfiles/scripts/06-macos.sh`

- [ ] **Step 1: Write the script**

```bash
cat > ~/Desktop/personal/dotfiles/scripts/06-macos.sh <<'EOF'
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
EOF
chmod +x ~/Desktop/personal/dotfiles/scripts/06-macos.sh
```

- [ ] **Step 2: Lint + dry test**

```bash
shellcheck ~/Desktop/personal/dotfiles/scripts/06-macos.sh
bash ~/Desktop/personal/dotfiles/scripts/06-macos.sh
```

Expected: roda o defaults.sh, imprime "✓ macos/defaults.sh aplicado".

- [ ] **Step 3: Commit**

```bash
cd ~/Desktop/personal/dotfiles
git add scripts/06-macos.sh
git commit -m "feat(scripts): 06-macos.sh — wrapper de defaults"
```

---

## Phase 4 — Orchestrator + .local hooks

### Task 16: install.sh

**Files:**
- Create: `~/Desktop/personal/dotfiles/install.sh`

- [ ] **Step 1: Write the entry point**

```bash
cat > ~/Desktop/personal/dotfiles/install.sh <<'EOF'
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
EOF
chmod +x ~/Desktop/personal/dotfiles/install.sh
```

- [ ] **Step 2: Lint**

```bash
shellcheck ~/Desktop/personal/dotfiles/install.sh
```

Expected: no errors.

- [ ] **Step 3: Smoke test (rodar inteiro contra a máquina atual)**

```bash
bash ~/Desktop/personal/dotfiles/install.sh
```

Expected: cada sub-script reporta seu estado (mostly no-ops em máquina já configurada). Final ends com mensagem "✓ Bootstrap completo".

- [ ] **Step 4: Commit**

```bash
cd ~/Desktop/personal/dotfiles
git add install.sh
git commit -m "feat: install.sh entry point"
```

---

### Task 17: Add .zshrc.local source line

**Files:**
- Modify: `~/Desktop/personal/dotfiles/stow/zsh/.zshrc` (last line)

- [ ] **Step 1: Verifique se já não tem**

```bash
grep -n 'zshrc.local' ~/Desktop/personal/dotfiles/stow/zsh/.zshrc || echo "MISSING — vou adicionar"
```

Expected: "MISSING" (assumindo que não tem). Se já tiver, skip pro próximo task.

- [ ] **Step 2: Append a linha**

```bash
cat >> ~/Desktop/personal/dotfiles/stow/zsh/.zshrc <<'EOF'

# Source per-machine overrides (gitignored). Coloca env vars privadas,
# aliases de trabalho, AWS_PROFILE alternativo aqui.
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
EOF
```

- [ ] **Step 3: Verify**

```bash
tail -5 ~/Desktop/personal/dotfiles/stow/zsh/.zshrc
```

Expected: mostra as últimas linhas com o source.

- [ ] **Step 4: Smoke test em shell interativo (sem .local file ainda — silent skip)**

```bash
zsh -i -c 'echo "OK"' 2>&1 | tail -3
```

Expected: "OK" sem erro (já que `~/.zshrc.local` não existe, o `[[ -f ]]` falha silencioso).

- [ ] **Step 5: Commit**

```bash
cd ~/Desktop/personal/dotfiles
git add stow/zsh/.zshrc
git commit -m "feat(zsh): source ~/.zshrc.local at end for per-machine overrides"
```

---

### Task 18: Add .gitconfig.local include

**Files:**
- Modify: `~/Desktop/personal/dotfiles/stow/git/.gitconfig`

- [ ] **Step 1: Verifique se já não tem**

```bash
grep -A1 '\[include\]' ~/Desktop/personal/dotfiles/stow/git/.gitconfig 2>/dev/null || echo "MISSING — vou adicionar"
```

- [ ] **Step 2: Append a seção include**

```bash
cat >> ~/Desktop/personal/dotfiles/stow/git/.gitconfig <<'EOF'

[include]
    path = ~/.gitconfig.local
EOF
```

- [ ] **Step 3: Verify git ainda funciona (não há .local; git ignora include faltando)**

```bash
git config --list | head -5
```

Expected: lista alguns valores. Sem erro mesmo sem o .local existir.

- [ ] **Step 4: Commit**

```bash
cd ~/Desktop/personal/dotfiles
git add stow/git/.gitconfig
git commit -m "feat(git): include ~/.gitconfig.local for per-machine email"
```

---

## Phase 5 — Smoke test + README

### Task 19: Re-run install.sh end-to-end

- [ ] **Step 1: Idempotency check**

```bash
bash ~/Desktop/personal/dotfiles/install.sh 2>&1 | tee /tmp/install-rerun.log
```

Expected: termina sem erro. Cada sub-script identifica que tudo já está aplicado (no-op).

- [ ] **Step 2: Verifique log**

```bash
grep -E '✓|→' /tmp/install-rerun.log | head -20
```

Expected: linhas indicam estado já configurado, sem erros.

- [ ] **Step 3: Verifique que o shell funciona**

```bash
zsh -i -c 'theme && echo $LS_COLORS | head -c 100'
```

Expected: "tema atual: light" + começo do LS_COLORS.

---

### Task 20: Write README.md

**Files:**
- Create: `~/Desktop/personal/dotfiles/README.md`

- [ ] **Step 1: Write user-facing quickstart**

```bash
cat > ~/Desktop/personal/dotfiles/README.md <<'EOF'
# dotfiles

Configs pessoais (shell, git, starship, claude, vscode, macOS defaults, homebrew).

## Bootstrap numa máquina nova

```bash
# 1. Xcode CLI tools (instala git junto)
xcode-select --install

# 2. Clone
git clone git@github.com:<owner>/dotfiles.git ~/Desktop/personal/dotfiles
cd ~/Desktop/personal/dotfiles

# 3. Bootstrap
./install.sh
```

Depois:
- `exec zsh` pra entrar no shell novo
- Logout/reboot pra defaults globais (key repeat) tomarem efeito completo
- Criar `~/.zshrc.local` e `~/.gitconfig.local` com env vars/email per-machine

## Estrutura

| Path | O que tem |
|---|---|
| `install.sh` | entry point — chama scripts em ordem |
| `Brewfile` | `brew bundle install` lê daqui |
| `stow/` | arquivos que viram symlinks no `$HOME` via GNU stow |
| `vscode/` | settings.json + keybindings.json (path em `~/Library/`) |
| `macos/defaults.sh` | todos os `defaults write` |
| `scripts/` | sub-scripts (01-prereqs → 06-macos) |

## Documentação

- `SPEC.md` — design completo, decisões, scope
- `CLAUDE.md` — playbook operacional (adicionar configs, manter o repo)

## Re-aplicar updates

```bash
cd ~/Desktop/personal/dotfiles
git pull
./install.sh   # sub-scripts são idempotentes, aplica só o que mudou
```

## Stack

GNU Stow + bash + Homebrew + oh-my-zsh + Starship + zsh-autosuggestions/syntax-highlighting + JetBrainsMono Nerd Font.

## Per-machine overrides

Arquivos `.local` ficam em `$HOME` e são **gitignored**:
- `~/.zshrc.local` — sourced no final do `.zshrc`. AWS_PROFILE, work tokens, etc.
- `~/.gitconfig.local` — incluído via `[include]`. Email diferente por máquina.
EOF
```

- [ ] **Step 2: Commit**

```bash
cd ~/Desktop/personal/dotfiles
git add README.md
git commit -m "docs: README.md user-facing quickstart"
```

---

### Task 21: Push to GitHub

- [ ] **Step 1: Criar o repo privado no GitHub**

Manualmente ou via `gh`:

```bash
gh repo create dotfiles --private --source=. --remote=origin
# OU se já existe remote:
git remote -v
```

Expected: `origin` apontando pro repo privado seu no GitHub.

- [ ] **Step 2: Push**

```bash
cd ~/Desktop/personal/dotfiles
git push -u origin master   # ou main, dependendo da branch default
```

Expected: push completo, com todos os commits.

- [ ] **Step 3: Verificar no GitHub**

Abrir `https://github.com/<owner>/dotfiles` no browser. Confirmar:
- Repo é **privado**
- README aparece na home
- Arquivos: `SPEC.md`, `CLAUDE.md`, `README.md`, `install.sh`, etc

---

## Phase 6 — VM test (manual, fora do escopo deste plano)

### Task 22: Test bootstrap numa VM macOS limpa

- [ ] Provisionar VM macOS (UTM/Parallels/Vagrant)
- [ ] No primeiro boot da VM: instalar git via `xcode-select --install`
- [ ] Clonar o repo (SSH ou HTTPS+gh login)
- [ ] Rodar `./install.sh`
- [ ] Verificar que termina sem erro
- [ ] Verificar que `zsh` carrega com tema, ícones renderizam (font + iTerm config manual antes), aliases funcionam
- [ ] Iterar se algo falhar — comum issue: oh-my-zsh install precisa de input se já tiver `.zshrc`; defaults precisam reboot

---

## Self-review checklist (pra mim, antes de entregar)

- [ ] Cada task tem caminho exato de file (create/modify)
- [ ] Steps são bite-size (2-5 min cada)
- [ ] Comandos shell completos, sem `...` ou `TBD`
- [ ] Verification steps com output esperado
- [ ] Commits pequenos e focados
- [ ] Idempotência verificada em cada script (re-run sem erro)
- [ ] PUA chars (Nerd Font) preservados na captura do starship TOML
- [ ] `.gitignore` cobre `**/.local` e segredos comuns
- [ ] SPEC e CLAUDE.md referenciados no README
