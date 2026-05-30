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

iTerm2 usa "Load preferences from a custom folder" apontando pra `iterm2/`, com
**save automático no quit** (configurado pelo `07-iterm2.sh`). Não precisa
re-capturar à mão — ao fechar o iTerm ele grava as prefs na pasta sozinho.

```bash
# 1. Mudou settings no iTerm2 (GUI). Ao FECHAR o iTerm (Cmd-Q), ele grava as prefs
#    na pasta do repo automaticamente — em XML, só as keys reais (filtra voláteis).
# 2. Confirma e commita o diff:
cd ~/Desktop/personal/dotfiles
git status              # iterm2/com.googlecode.iterm2.plist aparece se algo mudou
git diff iterm2/
git add iterm2/com.googlecode.iterm2.plist
git commit -m "iterm2: <o que mudou>"
```

**Nota:** o `git status` só suja quando você muda uma config de verdade — keys
voláteis (posição de janela, timestamps, bookmark blobs) têm prefixo `NoSync` e
o iTerm **não** as grava na pasta (`iTermRemotePreferences.m` l.105-108). O
primeiro quit numa máquina nova reescreve o plist pra essa versão filtrada (some
o lixo machine-specific da captura inicial). Apontar máquina nova: `bash
scripts/07-iterm2.sh` (e reabrir o iTerm).

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

### Theme switch ↔ cores do iTerm (fonte única = modo do macOS)

A função `theme light|dark` (em `stow/zsh/.zshrc`) troca prompt Starship /
syntax-highlighting / LS_COLORS / git colors **e dirige o appearance do macOS**
(System Events via `osascript`), na função `_bz_macos_appearance`.

**Quem renderiza as cores do terminal:** o profile do iTerm tem **"Use Separate
Colors for Light and Dark Mode" = 1** (`iterm2/com.googlecode.iterm2.plist`).
Então bg / foreground / cursor / seleção / **bold** / paleta ANSI vêm de slots
`(Light)`/`(Dark)` no plist, escolhidos **ao vivo pelo modo do macOS**. Logo,
fazer `theme dark` virar o macOS pra dark é o suficiente — o iTerm pinta tudo
pelo slot certo. **Fonte única de verdade = modo do macOS.**

- Slots dark: `Background Color (Dark)` ≈ `#15191f`, `Foreground Color (Dark)`
  ≈ `#dcdcdc`, `Bold Color (Dark)` = `#ffffff`.
- Slots light: `Background Color (Light)` ≈ `#e2e8f0`, `Foreground Color (Light)`
  ≈ `#101010`, `Bold Color (Light)` ≈ `#101010`.

**⚠ system-wide:** `theme dark` troca o **macOS inteiro** pra dark (Safari, Finder,
VS Code, tudo), não só o terminal. É intencional — vira um toggle único de tema.

**⚠ Automation/TCC no bootstrap:** o 1º `set dark mode` numa máquina nova dispara
o prompt de permissão de **Automation** do macOS (terminal → System Events) uma
vez. Aprovar; depois é silencioso. Sem aprovação o `osascript` falha quieto
(`2>/dev/null`) e o tema do terminal não troca.

**Por que NÃO usamos OSC (histórico):** versões antigas forçavam bg/fg/cursor/seleção
da sessão viva via OSC 11/10/12/1337 (`_bz_iterm_*`, removidas). O problema: **não
existe OSC para a cor de bold** — então forçar dark com macOS em Light deixava o
bold preso em `Bold Color (Light)` (≈preto) sobre bg escuro, ilegível. Dirigir o
macOS resolve na raiz e elimina a duplicação OSC↔plist.

**Key legada `Background Color` (sem sufixo):** é **ignorada na renderização** sob
separate-colors. O iTerm a mantém em `#fafafa` (sobra da 1ª captura) e a **reescreve
no quit**, então o valor versionado dela é `#fafafa` por design — **não edite à mão**
achando que é o bg claro: foi isso que gerou o diff fantasma `#e2e8f0 ↔ #fafafa`.
O bg claro real é o slot `(Light)`.

**Idempotência:** `_bz_macos_appearance` só dispara `osascript` se o modo atual
difere do pedido. Como o auto-detect do startup (`.zshrc`) **lê** o modo do macOS e
chama `theme`, o helper vira no-op no boot — sem latência extra por aba, sem loop.

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
