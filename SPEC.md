# Dotfiles — Spec

Documento de design do repo. Decisões tomadas durante o brainstorming inicial
e guia da implementação. Atualizar quando decisões mudarem.

---

## Goal

Versionar configs pessoais (terminal + macOS) de forma que:

1. **Reproduzir o setup atual em qualquer Mac novo** rodando um único script.
2. **Mover entre Macs no futuro** (pessoal, trabalho) sem refazer setup do zero.
3. **Re-aproveitar a parte de terminal em Linux** quando precisar (containers
   de dev, servidores, WSL futuramente).

## Non-goals (v1)

- Suporte a Windows nativo (WSL conta como Linux).
- Encryption de segredos no repo (sem `git-crypt`/`sops`). Segredos via
  `.local` files gitignored.
- Gerenciamento de versões de runtime (nvm, pyenv) além do já existente.

## Scope — v1

| Item | Versionado? | Como |
|---|---|---|
| `~/.zshrc` | ✓ | stow `zsh` |
| `~/.gitconfig` + `~/.gitignore_global` | ✓ | stow `git` |
| `~/.config/starship-*.toml` (light + dark) | ✓ | stow `starship` |
| `~/.claude/` (CLAUDE.md, settings, memory) | ✓ | stow `claude` |
| VS Code `settings.json` + `keybindings.json` | ✓ | cp script (path em `~/Library`) |
| VS Code extensions list | ✗ | sincronizado via Settings Sync (GitHub auth) do próprio VS Code |
| Homebrew formulas + casks | ✓ | `Brewfile` + `brew bundle install` |
| `macOS defaults` (key repeat, press-and-hold, etc) | ✓ | `macos/defaults.sh` |
| Oh My Zsh + plugins (autosuggestions, etc) | ✗ versão | instalado pelo `03-shell.sh` |
| Nerd Font (JetBrainsMono) | ✗ binário | `brew install --cask` no `02-brew.sh` |
| iTerm2 prefs | ✓ | `iterm2/com.googlecode.iterm2.plist` + "custom prefs folder" (lê no launch + salva no quit), configurado por `07-iterm2.sh` |

## Tooling

### GNU Stow + bash install script (escolhido)

**Por quê stow:** ferramenta minimalista (~40KB), faz UMA coisa bem feita —
cria symlinks de um diretório do repo pro `$HOME`. Cada subdir de `stow/`
corresponde a um "package" do stow, e a estrutura interna **espelha** o
layout final em `$HOME`. Zero magic, debug trivial (`ls -la ~ | grep -E
'zshrc|gitconfig'`).

**Por quê não chezmoi:** mais ferramenta do que necessário hoje. Templating
Go, convenções de nome (`dot_zshrc.tmpl`), execução por hooks — tudo
solucionável com bash explícito por enquanto. Reavaliar se o setup
crescer pra 4+ máquinas com configs realmente divergentes.

**Por quê não bash puro com `ln -sf`:** stow gerencia o ciclo de vida dos
symlinks (delete, restow, dry-run), o que dá robustez de graça.

## Repo structure

```
dotfiles/
├── SPEC.md                       # este arquivo
├── README.md                     # quickstart user-facing (criado depois)
├── install.sh                    # entry point: chama scripts/* em ordem
├── Brewfile                      # `brew bundle install` lê daqui
├── .gitignore
│
├── stow/                         # cada subdir = um package do stow
│   ├── zsh/
│   │   └── .zshrc
│   ├── git/
│   │   ├── .gitconfig
│   │   └── .gitignore_global
│   ├── starship/
│   │   └── .config/
│   │       ├── starship-light.toml
│   │       └── starship-dark.toml
│   └── claude/
│       └── .claude/
│           ├── CLAUDE.md
│           ├── settings.json
│           └── memory/           # subarvore com .md files
│
├── vscode/                       # paths em ~/Library/* — não stow, copy
│   ├── settings.json
│   └── keybindings.json
│
├── macos/
│   └── defaults.sh               # todos os `defaults write`, idempotente
│
└── scripts/
    ├── 01-prereqs.sh             # xcode CLI, homebrew
    ├── 02-brew.sh                # brew bundle install
    ├── 03-shell.sh               # oh-my-zsh + plugins + fonts
    ├── 04-stow.sh                # stow -t ~ -d stow zsh git starship claude
    ├── 05-vscode.sh              # cp settings + install-extension loop
    └── 06-macos.sh               # bash macos/defaults.sh
```

## `install.sh` — fluxo

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

bash scripts/01-prereqs.sh
bash scripts/02-brew.sh
bash scripts/03-shell.sh
bash scripts/04-stow.sh
bash scripts/05-vscode.sh
bash scripts/06-macos.sh

echo "✓ Bootstrap completo. Rode 'exec zsh' pra entrar no novo shell."
```

**Propriedades exigidas:**

- **Idempotente:** rodar 2× não dá erro nem corrompe. Cada sub-script verifica
  antes de fazer (ex: `command -v brew >/dev/null || /bin/bash -c "$(curl -fsSL ...)"`).
- **Subscript isolado:** `bash scripts/02-brew.sh` funciona standalone, sem
  precisar rodar o install.sh inteiro. Útil pra debugar ou re-aplicar só uma
  parte.
- **Sem `sudo` global:** cada comando pede sudo quando precisar. Não rodar
  o script inteiro com sudo (alguns comandos quebram).

## Sub-scripts — responsabilidades

### `01-prereqs.sh`
- Garante Xcode CLI tools instalado (`xcode-select --install` se faltar).
- Garante Homebrew (instala via curl se faltar).
- Aceita prompts não-interativos onde possível.

### `02-brew.sh`
- `brew update` (silencioso).
- `brew bundle install --file=Brewfile`.

### `03-shell.sh`
- Instala Oh My Zsh em `~/.oh-my-zsh` se faltar (RUNZSH=no pra não trocar shell durante install).
- Clona os 3 plugins em `$ZSH_CUSTOM/plugins/`:
  - `zsh-completions`
  - `zsh-autosuggestions`
  - `zsh-syntax-highlighting`
- Fonte JetBrainsMono Nerd Font: instalada via Brewfile (`brew install --cask font-jetbrains-mono-nerd-font`), nada a fazer aqui.

### `04-stow.sh`
- `cd stow && stow -t "$HOME" zsh git starship claude`.
- Antes do stow: para cada destino, verifica se há arquivo regular existente.
  Se houver (não-symlink), faz backup pra `~/.dotfiles-backup/<timestamp>/`.
- Mensagem clara sobre conflitos.

### `05-vscode.sh`
- Verifica que `code` CLI está disponível (Brewfile instala `visual-studio-code` via cask).
- Copia `vscode/settings.json` e `vscode/keybindings.json` pro path do User do VS Code (`~/Library/Application Support/Code/User/`).
- Extensions NÃO são gerenciadas aqui — usar Settings Sync do VS Code via GitHub login.

### `06-macos.sh`
- Executa `bash macos/defaults.sh`.
- Avisa o usuário que algumas mudanças precisam logout/reboot pra surtir efeito completo.

## `macos/defaults.sh` — conteúdo inicial

Capturado via scan automático dos defaults customizados (★ = valor difere do
default de fábrica do macOS). 19 entries iniciais:

```bash
#!/usr/bin/env bash
set -euo pipefail

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

# ================================ DOCK ===================================
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 46
defaults write com.apple.dock magnification -bool true
defaults write com.apple.dock show-recents -bool false

# =============================== APPEARANCE ==============================
defaults write -g AppleShowScrollBars -string "Always"
defaults write -g AppleHighlightColor -string "0.698039 0.843137 1.000000 Blue"

# =============================== HOT CORNERS =============================
# Action codes: 0=none, 2=mission-control, 3=app-windows, 4=desktop,
# 5=screen-saver, 10=display-sleep, 11=launchpad, 12=notif-center,
# 13=lock-screen, 14=quick-note
defaults write com.apple.dock wvous-br-corner -int 14         # bottom-right = Quick Note

# =========================== TRACKPAD BLUETOOTH ==========================
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# ============================ SCREENCAPTURE ==============================
defaults write com.apple.screencapture type -string "jpg"

# ================== Restart de apps afetados (idempotente) ===============
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true
echo "✓ defaults aplicados. Logout/reboot pra mudanças globais (key repeat, etc) tomarem efeito completo."
```

**Como manter:** sempre que aplicar um `defaults write` novo manualmente,
adicionar a linha aqui. O scan de descoberta inicial cobriu ~30 keys
relevantes; pra um audit periódico, rodar o script de scan e ver se algum
novo ★ apareceu.

## Multi-machine — estratégia

### `~/.zshrc.local` (gitignored)
Sourced no FINAL do `.zshrc` versionado:

```zsh
# .zshrc — última linha
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
```

Esse arquivo NÃO vai pro repo. Cada Mac mantém o próprio com:
- `AWS_PROFILE` se diferente do default
- Aliases de trabalho específicos
- Env vars de tokens/keys
- Override de qualquer coisa do `.zshrc` versionado

### `~/.gitconfig.local` (gitignored)
Incluído via `[include]` no `.gitconfig` versionado:

```ini
[include]
    path = ~/.gitconfig.local
```

`gitconfig.local` contém `[user] email = ...` específico daquela máquina.
Mac pessoal pode ter email pessoal, Mac de trabalho pode ter email corp.

### Outros `.local` patterns
- `~/.claude/CLAUDE.local.md` (se quiser instruções por-máquina pro Claude)
- `Brewfile.local` (formulas extras só dessa máquina)

## Linux compat — terminal portion

`.zshrc` envolve blocos macOS-specific em guard:

```zsh
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS-specific (homebrew prefix, defaults read pro auto-detect de modo, etc)
fi
```

O grosso do `.zshrc` (theme function, ZSH_HIGHLIGHT_STYLES, aliases neutros,
starship init) **funciona idêntico em Linux**. Oh My Zsh, Starship,
zsh-syntax-highlighting — todos têm versões Linux nativas.

Quando chegar a hora de rodar em Linux:
- Skip `02-brew.sh` (Brewfile é macOS-only)
- Skip `06-macos.sh` (defaults é macOS-only)
- `03-shell.sh` precisa adaptação leve: `apt install zsh git stow curl` no
  Linux antes do oh-my-zsh setup
- Rest funciona

Não vamos implementar Linux-paths agora, mas a estrutura modular já permite.

## Secret handling

### `.gitignore` (essencial)
```
# Local overrides — nunca commitar
**/.local
.zshrc.local
.gitconfig.local
.claude/CLAUDE.local.md
Brewfile.local

# Credenciais que NUNCA deveriam estar aqui mas guard-rail
*.pem
*.key
id_rsa*
id_ed25519*
.env
.env.*
!.env.example

# OS / editor
.DS_Store
*.swp
*.swo
.idea/
.vscode/   # ironicamente — o que está em /vscode/ é setting versionado, mas .vscode/ workspace local não vai
```

### Audit manual antes de tornar público
Mesmo com repo privado, fazer um sweep:
```bash
git ls-files | xargs grep -l -E '(AKIA|sk-|ghp_|github_pat_|password|secret)' 2>/dev/null
```

Idealmente integrar `gitleaks` ou similar como pre-commit hook (futuro).

## Implementation order (tasks a serem executadas)

Marcar conforme avançar:

1. **Inicial setup do repo** (já feito — `.git` existe)
2. **Capturar arquivos atuais**:
   - Copiar `~/.zshrc` → `stow/zsh/.zshrc`
   - Copiar `~/.gitconfig` → `stow/git/.gitconfig`
   - Copiar `~/.config/starship-*.toml` → `stow/starship/.config/`
   - Copiar `~/.claude/CLAUDE.md` e estrutura → `stow/claude/.claude/`
3. **Gerar Brewfile**: `brew bundle dump --file=Brewfile`
4. **VS Code captures** (extensions sincronizam via Settings Sync, não versionamos):
   - Copiar `~/Library/Application Support/Code/User/settings.json` → `vscode/`
   - Copiar `keybindings.json` se existir
5. **Escrever `macos/defaults.sh`** com as defaults atuais
6. **Escrever sub-scripts** (`01-` ao `06-`)
7. **Escrever `install.sh`** que orquestra os 6 sub-scripts
8. **Adicionar `.gitignore`**
9. **Modificar `~/.zshrc` no source** pra:
   - Sourcing `~/.zshrc.local` no final
   - (opcional) Adicionar guards de OS detection nos blocos macOS-specific
10. **Modificar `~/.gitconfig`** pra incluir `~/.gitconfig.local`
11. **Testar install.sh em sandbox** (idealmente VM ou usuário macOS test)
12. **README.md** user-facing com quickstart
13. **Commit inicial + push pro GitHub privado**

## Testing strategy

Bootstrap testado em **VM macOS limpa**, não no Mac do dev. Isso valida que
`install.sh` cobre todas as deps (sem assumir nada já instalado), e que a
ordem dos sub-scripts é correta. Iterar até `vagrant up && bash install.sh`
(ou equivalente UTM/Parallels) terminar limpo.

## Decisões já fechadas

- **Sem auto-update.** Repo é puxado/aplicado manualmente. Sem `cron`,
  sem hook que faz `git pull` no boot. Cada update é uma ação consciente.
- **VS Code extensions** sincronizam via Settings Sync (GitHub login),
  não versionamos a lista no repo.
- **iTerm2 prefs** versionadas via "Load preferences from a custom folder", **não**
  symlink do plist (o `cfprefsd` reescreve/ignora symlinks em `~/Library/Preferences`).
  Modo **sync**: lê da pasta no launch e salva de volta no quit automaticamente
  (`07-iterm2.sh` seta `LoadPrefsFromCustomFolder` + save-on-quit "Always"). O iTerm
  grava só keys syncable (filtra `NoSync/NS/SU/UK`) em XML → diffs limpos e legíveis.

## Open questions / decisões adiadas

- Worth setup pre-commit hook com `gitleaks` (proteção contra commit acidental de segredo)?
- Versionar `~/.tmux.conf` (não temos hoje, mas se adicionar)?
- Capturar configurações de aplicativos GUI (Rectangle, Karabiner, etc) — ainda fora do scope.
