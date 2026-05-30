# CLAUDE.md — Playbook deste repo de dotfiles

Documento operacional pra Claude (e pro dono do repo). Lê ANTES de mexer aqui.
Spec arquitetural completa: ver `SPEC.md`.

---

## O que esse repo faz

Versiona configs pessoais (shell, git, starship, claude, vscode, macOS defaults,
homebrew packages). Permite reproduzir o setup completo numa máquina nova
rodando um único script (`./install.sh`).

**Não é auto-update.** Pull e re-aplicação são ações manuais e conscientes.

---

## Operações mais comuns

### Bootstrap numa máquina nova

```bash
# 1. Pré-requisitos absolutos: git
xcode-select --install   # se faltar (instala git também)

# 2. Clone (precisa de acesso ao repo privado — SSH ou gh CLI)
git clone git@github.com:<owner>/dotfiles.git ~/Desktop/personal/dotfiles
cd ~/Desktop/personal/dotfiles

# 3. Bootstrap
./install.sh
```

O `install.sh` chama em sequência `scripts/01-prereqs.sh` … `06-macos.sh`.
Cada um é **idempotente** — rodar 2× não quebra.

Depois do bootstrap:
- `exec zsh` pra entrar no shell novo
- Logout/reboot pra alguns defaults (key repeat global) tomarem efeito completo
- Criar `~/.zshrc.local` e `~/.gitconfig.local` se essa máquina precisar de
  customizações específicas (AWS_PROFILE, email diferente, tokens, etc)

### Adicionar um novo dotfile ao versionamento

Cenário: você customizou `~/.tmux.conf` localmente e quer trackear.

```bash
mkdir -p stow/tmux
mv ~/.tmux.conf stow/tmux/.tmux.conf
cd stow && stow -t "$HOME" tmux   # recria o symlink
```

Aí adicionar `tmux` à lista do `04-stow.sh` (`stow zsh git starship claude tmux`).
Commit.

### Adicionar um novo brew package ao Brewfile

```bash
brew install ripgrep              # instala localmente
brew bundle dump --file=Brewfile --force   # regenera Brewfile

# OU manualmente, mais cirúrgico:
echo 'brew "ripgrep"' >> Brewfile
```

Commit o Brewfile.

### Capturar um novo macOS default que você setou manualmente

Cenário: rodou `defaults write com.apple.dock orientation -string "left"` e
gostou.

```bash
# Adiciona a linha equivalente em macos/defaults.sh
echo 'defaults write com.apple.dock orientation -string "left"' >> macos/defaults.sh

# Re-rodar o script numa máquina deveria reaplicar idempotentemente:
bash macos/defaults.sh
```

Pra **descobrir** o que você mexeu sem lembrar: rodar o **scan de drift**
(ver "Scripts utilitários" abaixo) — compara teus defaults atuais contra o
que já está no `defaults.sh` e te mostra os novos.

### Atualizar o repo após mudar algo

Workflow típico:

```bash
# 1. Mudou .zshrc no $HOME (que é symlink pro repo) — já tá refletido
# 2. Confirma o git diff
cd ~/Desktop/personal/dotfiles
git status
git diff

# 3. Commit + push
git add stow/zsh/.zshrc
git commit -m "zshrc: add aliases for X"
git push
```

**Importante:** como o `.zshrc` em `$HOME` é symlink pro arquivo no repo,
editar `~/.zshrc` muda o arquivo do repo direto. Não precisa "sincronizar"
nada — só commitar.

### Aplicar updates do repo em outra máquina

```bash
cd ~/Desktop/personal/dotfiles
git pull

# Sub-scripts são idempotentes — re-rodar reaplica o que mudou
./install.sh    # ou só o script específico, ex: bash scripts/06-macos.sh
```

### Atualizar config do iTerm2

iTerm2 usa "Load preferences from a custom folder" (load-only) apontando pra
`iterm2/`. Como é load-only, o iTerm **não** reescreve a pasta sozinho — pra
versionar uma mudança você re-captura:

```bash
# 1. Mudou settings no iTerm2 (GUI). Re-captura o plist efetivo pro repo:
cp ~/Library/Preferences/com.googlecode.iterm2.plist iterm2/com.googlecode.iterm2.plist
plutil -convert xml1 iterm2/com.googlecode.iterm2.plist   # diffs legíveis

# 2. Commit
git add iterm2/com.googlecode.iterm2.plist
git commit -m "iterm2: <o que mudou>"
```

**Gotcha (load-only):** o iTerm lê da pasta no launch mas salva mudanças da sessão
em `~/Library/Preferences`. Re-capture **antes** de reabrir o iTerm — senão o
próximo launch recarrega a versão antiga da pasta e suas mudanças somem. Apontar
máquina nova pra essa pasta: `bash scripts/07-iterm2.sh` (e reabrir o iTerm).

---

## Arquitetura — pontos críticos

### Stow vs scripts

Stow gerencia **só symlinks de arquivos cujo destino fica em `$HOME`**
(zsh, git, starship, claude). Cada subdir de `stow/` espelha estrutura final:

```
stow/zsh/.zshrc                    → ~/.zshrc
stow/starship/.config/foo.toml     → ~/.config/foo.toml
```

Coisas que ficam em `~/Library/...` (VS Code settings, app preferences)
**não usam stow** — usa `cp` no script `05-vscode.sh`. O path é macOS-specific
e não casa com a abstração do stow.

### Idempotência: regra de ouro

Todo sub-script deve poder rodar 2× sem corromper. Padrões:

```bash
# Antes de instalar algo, checa
command -v brew >/dev/null || /bin/bash -c "$(curl -fsSL ...)"

# Antes de criar dir, -p
mkdir -p ~/.dotfiles-backup

# defaults write é naturalmente idempotente (último write ganha)

# Cp com -f não falha se destino existe
cp -f vscode/settings.json "$VSCODE_USER/settings.json"

# Stow restow se já tem symlinks
stow -R -t "$HOME" -d stow zsh git starship claude
```

### `.local` files: o mecanismo per-machine

A **referência** ao `.local` está versionada no `.zshrc` / `.gitconfig`:
- `[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local`
- `[include] path = ~/.gitconfig.local` (no `.gitconfig`)

O **conteúdo** dos `.local` files está no `.gitignore`. Cada máquina cria
o próprio. Use pra: AWS profile, work email, work tokens, paths específicos.

---

## Scripts utilitários (futuros)

Vale criar ao longo do tempo, em `scripts/utils/`:

- **`scan-defaults-drift.py`** — lê todos os `defaults write` do `macos/defaults.sh`,
  compara contra o que está aplicado no sistema agora, e mostra o que foi
  mudado fora do script (drift). Cobre o caso "fui mexendo no System Settings
  manual e esqueci de versionar".

- **`audit-secrets.sh`** — grep por padrões comuns de secret no repo
  (`AKIA*`, `sk-*`, `ghp_*`, `password=*`). Rodar antes de tornar repo
  público (se for o caso).

- **`uninstall.sh`** — reverte os symlinks (`stow -D ...`) e remove os
  defaults customizados. Útil pra testar bootstrap from scratch sem
  precisar de VM.

---

## Pitfalls / cuidados

### Não commitar segredos

Mesmo sendo repo privado:
- ❌ AWS keys, GitHub tokens, SSH keys → vão em `~/.zshrc.local` (gitignored)
- ❌ Senhas, API keys → vão em `~/.zshrc.local`
- ✓ Email pessoal no `.gitconfig` versionado → OK (já visível em commits seus)
- ✓ Profile names AWS (sem credenciais) → OK

`.gitignore` já cobre `**/.local`, `*.pem`, `id_rsa*`, `.env*`. Mas quando
adicionar dotfile novo, **olhar o conteúdo antes de commit**.

### Cuidado com Unicode da Private Use Area

Os ícones Nerd Font (U+E000-U+F8FF, U+F0000+) que aparecem nos starship TOMLs
podem ser estripados silenciosamente por pipelines de tooling de AI/agentes.
**Sempre que mexer nesses arquivos via script de agent**: verificar bytes com
`xxd` ou `grep -P "\xee\x9c\x98"` (ou similar pro codepoint relevante)
**antes** de declarar "feito". Detalhe pleno desse problema está no
`~/.oh-my-zsh/CLAUDE.md` (lições da sessão de criação do tema).

### Sub-scripts independentes

Cada `scripts/0X-*.sh` precisa funcionar standalone:

```bash
bash scripts/04-stow.sh    # deveria funcionar mesmo sem rodar 01/02/03 antes
```

Se um sub-script depender de outro (ex: 04-stow depende do GNU stow estar
instalado, que vem do 02-brew), ele deve **detectar e falhar com mensagem
clara**, não silenciosamente quebrar.

### Cuidado com defaults que dependem de versão do macOS

Alguns keys mudam de nome entre versões. Exemplo histórico:
`NSGlobalDomain NSWindowResizeTime` foi descontinuado em algum macOS recente.
Se um `defaults write` falhar silenciosamente (não dá erro mas não tem efeito),
verificar a key num release recente.

---

## Quando perguntar antes de agir

Mesmo seguindo CLAUDE.md, peça confirmação antes de:

- Adicionar/remover sub-script no `install.sh` (afeta ordem do bootstrap)
- Reorganizar a estrutura do `stow/` (rompe symlinks existentes em máquinas que já bootstrapparam)
- Tornar o repo público (audit de segredos obrigatório antes)
- Mudar a estratégia de tooling (stow → chezmoi etc) — exige migração

---

## Referências externas úteis

- Repo do GNU Stow: <https://www.gnu.org/software/stow/manual/stow.html>
- Catálogo de macOS defaults: <https://macos-defaults.com/>
- Starship config docs: <https://starship.rs/config/>
- Oh My Zsh: <https://github.com/ohmyzsh/ohmyzsh>
