# Homebrew — deve vir antes de /usr/bin (brew doctor)
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    git
    zsh-completions
    zsh-autosuggestions
    zsh-syntax-highlighting
    )

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
eval "$(starship init zsh)"
export PATH="$HOME/.local/bin:$PATH"

# Fallback do AWS_PROFILE: se nenhuma ferramenta (aws-vault, aws-sso) tiver
# setado o env var, assume "default" — daí o segmento AWS do prompt mostra
# algo sempre. Usa o idioma `${VAR:=val}` que só atribui se VAR estiver vazio.
: "${AWS_PROFILE:=default}"
export AWS_PROFILE

# ============================================================================
# Light/Dark theme toggle (prompt + syntax highlighting)
# Uso: `theme light`, `theme dark`, ou `theme` pra ver o atual.
# ============================================================================

# Paleta light (códigos xterm-256, mapeiam aos hex do starship-light.toml):
#   28 = #008700 verde escuro     124 = #af0000 vermelho terra
#   94 = #875f00 mostarda escura   60 = #5f5f87 cinza-azulado
#   24 = #005f87 azul-petróleo
_bz_highlight_light() {
  ZSH_HIGHLIGHT_STYLES[command]='fg=28'
  ZSH_HIGHLIGHT_STYLES[builtin]='fg=28'
  ZSH_HIGHLIGHT_STYLES[function]='fg=28'
  ZSH_HIGHLIGHT_STYLES[alias]='fg=28'
  ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=124,bold'
  ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=94'
  ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=94'
  ZSH_HIGHLIGHT_STYLES[comment]='fg=60'
  ZSH_HIGHLIGHT_STYLES[path]='fg=24,underline'
}

# Paleta dark (espelho do starship-dark.toml):
#  114 = #87d787 verde claro      210 = #ff8787 coral
#  222 = #ffd787 amarelo claro    103 = #8787af lavanda
#   75 = #5fafd7 azul claro
_bz_highlight_dark() {
  ZSH_HIGHLIGHT_STYLES[command]='fg=114'
  ZSH_HIGHLIGHT_STYLES[builtin]='fg=114'
  ZSH_HIGHLIGHT_STYLES[function]='fg=114'
  ZSH_HIGHLIGHT_STYLES[alias]='fg=114'
  ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=210,bold'
  ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=222'
  ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=222'
  ZSH_HIGHLIGHT_STYLES[comment]='fg=103'
  ZSH_HIGHLIGHT_STYLES[path]='fg=75,underline'
}

# LS_COLORS — usado pelo zsh tab-completion (e por GNU ls).
# Formato: type=ansi-code, separado por `:`. Tipos relevantes:
#   di=dir, ln=symlink, ex=executável, pi=pipe, so=socket,
#   bd=block-dev, cd=char-dev, su=setuid, sg=setgid,
#   tw=dir sticky+writable, ow=dir other-writable
# Após mudar LS_COLORS preciso re-rodar a zstyle, senão o cache fica velho.
_bz_lscolors_light() {
  # Prefixo `1;` em cada par = bold (SGR 1) antes da cor 256-color
  export LS_COLORS='di=1;38;5;24:ln=1;38;5;90:ex=1;38;5;28:pi=1;38;5;60:so=1;38;5;60:bd=1;38;5;60:cd=1;38;5;60:su=1;38;5;124:sg=1;38;5;124:tw=1;38;5;24:ow=1;38;5;24'
  zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
}

_bz_lscolors_dark() {
  export LS_COLORS='di=1;38;5;75:ln=1;38;5;139:ex=1;38;5;114:pi=1;38;5;103:so=1;38;5;103:bd=1;38;5;103:cd=1;38;5;103:su=1;38;5;210:sg=1;38;5;210:tw=1;38;5;75:ow=1;38;5;75'
  zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
}

# Cores do iTerm na SESSÃO VIVA via OSC escapes (NÃO toca no plist do custom
# folder — ele é reescrito no quit, editar em runtime é frágil). Como theme()
# roda no startup do shell, toda aba nova auto-aplica a cor no 1º prompt.
# OSC 11=background, 10=foreground, 12=cursor; selbg via OSC 1337 (iTerm-only).
# Guard TERM_PROGRAM: não emite escape em Terminal.app, VS Code, Linux, etc.
_bz_iterm_light() {
  [[ "$TERM_PROGRAM" == "iTerm.app" ]] || return 0
  printf '\033]11;#e2e8f0\007'                  # background slate-claro (= Gojo Limitless Light)
  printf '\033]10;#101010\007'                  # foreground near-black
  printf '\033]12;#000000\007'                  # cursor black
  printf '\033]1337;SetColors=selbg=b3d7ff\007' # selection light blue
}

_bz_iterm_dark() {
  [[ "$TERM_PROGRAM" == "iTerm.app" ]] || return 0
  printf '\033]11;#1e1e2e\007'                  # background dark slate
  printf '\033]10;#e2e8f0\007'                  # foreground light
  printf '\033]12;#e2e8f0\007'                  # cursor light
  printf '\033]1337;SetColors=selbg=3a4a6e\007' # selection muted blue
}

theme() {
  case "$1" in
    light)
      export STARSHIP_CONFIG="$HOME/.config/starship-light.toml"
      _bz_highlight_light
      _bz_lscolors_light
      _bz_git_colors_light
      _bz_iterm_light
      ;;
    dark)
      export STARSHIP_CONFIG="$HOME/.config/starship-dark.toml"
      _bz_highlight_dark
      _bz_lscolors_dark
      _bz_git_colors_dark
      _bz_iterm_dark
      ;;
    "")
      local current=light
      [[ $STARSHIP_CONFIG == *dark* ]] && current=dark
      echo "tema atual: $current — uso: theme light|dark"
      ;;
    *)
      echo "uso: theme light|dark"
      return 1
      ;;
  esac
}


# Usa GNU ls (gls do coreutils) em vez do BSD ls do macOS — para que respeite
# o LS_COLORS calibrado (BSD ls ignora LS_COLORS, usa só o LSCOLORS limitado a 8 cores).
alias ls='gls --color=auto --group-directories-first'

# Cores do `git log --decorate` (HEAD, branches, remotes, tags, stash).
# Git escreve no ~/.gitconfig global, então persiste entre sessões — toda
# invocação do theme reescreve. Códigos = 256-color (compatível com git antigo).
_bz_git_colors_light() {
  # decorate (HEAD, branches, refs em git log)
  git config --global color.decorate.HEAD         "bold 124"   # vermelho terra
  git config --global color.decorate.branch       "bold 28"    # verde escuro
  git config --global color.decorate.remoteBranch "bold 94"    # mostarda escura
  git config --global color.decorate.tag          "bold 60"    # cinza-azulado
  git config --global color.decorate.stash        "bold 124"
  # diff (file/hunk metadata, linhas removidas/adicionadas)
  git config --global color.diff.commit     "bold 94"          # hash commit em patches
  git config --global color.diff.meta       "60"               # header arquivo
  git config --global color.diff.frag       "bold 94"          # header @@ hunk (era cyan)
  git config --global color.diff.func       "60"               # nome função no hunk
  git config --global color.diff.old        "124"              # linhas removidas
  git config --global color.diff.new        "28"               # linhas adicionadas
  git config --global color.diff.whitespace "reverse 124"      # whitespace errors
}

_bz_git_colors_dark() {
  # decorate
  git config --global color.decorate.HEAD         "bold 210"   # coral
  git config --global color.decorate.branch       "bold 114"   # verde claro
  git config --global color.decorate.remoteBranch "bold 215"   # mostarda clara
  git config --global color.decorate.tag          "bold 146"   # lavanda
  git config --global color.decorate.stash        "bold 210"
  # diff
  git config --global color.diff.commit     "bold 215"
  git config --global color.diff.meta       "103"
  git config --global color.diff.frag       "bold 215"
  git config --global color.diff.func       "103"
  git config --global color.diff.old        "210"
  git config --global color.diff.new        "114"
  git config --global color.diff.whitespace "reverse 210"
}
# Auto-detect no boot do shell baseado no modo do macOS
if defaults read -g AppleInterfaceStyle 2>/dev/null | grep -qi dark; then
  theme dark
else
  theme light
fi

# Source per-machine overrides (gitignored). Coloca env vars privadas,
# aliases de trabalho, AWS_PROFILE alternativo aqui.
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
