#!/usr/bin/env zsh

input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')

# repo-relative path (repo/sub/dir) + branch when inside git, else ~-abbreviated cwd
git_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
if [ -n "$git_root" ]; then
  rel_path="${cwd#$git_root}"
  rel_path="${rel_path#/}"
  display_path="$(basename "$git_root")${rel_path:+/$rel_path}"

  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  dirty=$(git -C "$cwd" diff --quiet --ignore-submodules HEAD 2>/dev/null; [ $? -eq 1 ] && echo "*")
  git_info=" ${branch}${dirty}"
else
  display_path=$(echo "$cwd" | sed "s|^$HOME|~|")
  git_info=""
fi

model=$(echo "$input" | jq -r '.model.display_name // empty')
effort=$(echo "$input" | jq -r '.effort.level // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')

BLUE=$'\033[94m'; ORANGE=$'\033[38;2;217;119;87m'; DIM=$'\033[2m'; YEL=$'\033[33m'; RED=$'\033[31m'; RESET=$'\033[0m'

# pct <value> <warn> <crit>: prints "NN%" dim below warn, yellow >= warn, red >= crit
pct() {
  local v; v=$(printf '%.0f' "$1")
  local c=$DIM
  if (( v >= $3 )); then c=$RED; elif (( v >= $2 )); then c=$YEL; fi
  printf '%s%s%%%s' "$c" "$v" "$RESET"
}

line1="${BLUE}${display_path}${RESET}${DIM}${git_info}${RESET}"

# line2: "Model · effort · ctx NN% · 5h NN%" — segments joined with " · ", absent ones skipped
segs=()
[ -n "$model" ]  && segs+=("${ORANGE}${model}${RESET}")
[ -n "$effort" ] && segs+=("${DIM}${effort}${RESET}")
[ -n "$used" ]   && segs+=("${DIM}ctx $(pct "$used" 60 85)")
[ -n "$five" ]   && segs+=("${DIM}5h $(pct "$five" 80 95)")
sep="${DIM} · ${RESET}"; line2="${(pj:$sep:)segs}"

printf '%s\n%s' "$line1" "$line2"
