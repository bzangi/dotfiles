#!/usr/bin/env zsh
# Keepalive da barra de progresso (OSC 9;4) do Ghostty enquanto o Claude trabalha.
# Ghostty apaga o progresso 15s após o último update (SurfaceView_AppKit.swift) e o
# Claude Code só emite o OSC quando o estado muda, então em turnos longos a barra some.
#   UserPromptSubmit        → sobe loop que reenvia "indeterminate" a cada 10s
#   Pre/PostToolUse         → renova o heartbeat do loop
#   Stop/StopFailure/SessionEnd → mata o loop e limpa a barra
# ponytail: Esc não dispara hook; após interrupt a barra dura até o heartbeat expirar (TTL).
[[ $TERM_PROGRAM == ghostty ]] || exit 0

TTL=180
input=$(cat)
event=$(jq -r '.hook_event_name' <<<"$input")
sid=$(jq -r '.session_id' <<<"$input")
dir="${TMPDIR:-/tmp}/claude-progress"
mkdir -p "$dir"
state="$dir/$sid"   # "<loop pid> <tty>"; mtime = heartbeat

stop_loop() {
  [[ -f $state ]] || return 0
  local pid tty
  read -r pid tty < "$state"
  kill "$pid" 2>/dev/null
  rm -f "$state"
  [[ -w /dev/$tty ]] && printf '\e]9;4;0\a' > "/dev/$tty"
}

case $event in
  PreToolUse|PostToolUse)
    [[ -f $state ]] && touch "$state"
    ;;
  UserPromptSubmit)
    stop_loop
    # o hook não tem tty de controle: sobe a árvore até o processo do claude que tem
    p=$$ t=
    while (( p > 1 )); do
      t=$(ps -o tty= -p $p | tr -d ' ')
      [[ -n $t && $t != '??' ]] && break
      p=$(ps -o ppid= -p $p | tr -d ' ')
    done
    [[ -n $t && $t != '??' && -w /dev/$t ]] || exit 0
    print "0 $t" > "$state"   # existe antes do loop checar
    (
      while kill -0 $p 2>/dev/null && [[ -f $state ]] \
        && (( $(date +%s) - $(/usr/bin/stat -f %m "$state") < TTL )); do
        printf '\e]9;4;3\a' > "/dev/$t"
        sleep 10
      done
    ) </dev/null &>/dev/null &!
    print "$! $t" > "$state"
    ;;
  Stop|StopFailure|SessionEnd)
    stop_loop
    ;;
esac
exit 0
