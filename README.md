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
- Reabrir o iTerm2 (Cmd-Q + abrir) pra ele carregar as prefs versionadas
- Criar `~/.zshrc.local` e `~/.gitconfig.local` com env vars/email per-machine

## Estrutura

| Path | O que tem |
|---|---|
| `install.sh` | entry point — chama scripts em ordem |
| `Brewfile` | `brew bundle install` lê daqui |
| `stow/` | arquivos que viram symlinks no `$HOME` via GNU stow |
| `vscode/` | settings.json + keybindings.json (path em `~/Library/`) |
| `iterm2/` | prefs do iTerm2 (custom prefs folder, lê no launch + salva no quit) |
| `macos/defaults.sh` | todos os `defaults write` |
| `scripts/` | sub-scripts (01-prereqs → 07-iterm2) |

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
