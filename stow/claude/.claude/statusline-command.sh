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

BLUE=$'\033[94m'; ORANGE=$'\033[38;2;217;119;87m'; DIM=$'\033[2m'; YEL=$'\033[33m'; RED=$'\033[31m'; MAGENTA=$'\033[35m'; RESET=$'\033[0m'

# pct <value> <warn> <crit>: prints "NN%" dim below warn, yellow >= warn, red >= crit
pct() {
  local v; v=$(printf '%.0f' "$1")
  local c=$DIM
  if (( v >= $3 )); then c=$RED; elif (( v >= $2 )); then c=$YEL; fi
  printf '%s%s%s%%%s' "$RESET" "$c" "$v" "$RESET"
}

line1="${BLUE}${display_path}${RESET}${DIM}${git_info}${RESET}"

# line2: "Model · effort · ctx NN% · 5h NN%" — segments joined with " · ", absent ones skipped
segs=()
[ -n "$model" ]  && segs+=("${ORANGE}${model}${RESET}")
[ -n "$effort" ] && segs+=("${DIM}${effort}${RESET}")
[ -n "$used" ]   && segs+=("${DIM}ctx $(pct "$used" 60 85)")
[ -n "$five" ]   && segs+=("${DIM}5h $(pct "$five" 80 95)")
sep="${DIM} · ${RESET}"; line2="${(pj:$sep:)segs}"

# line3: PRs this session opened, from Claude Code's own "pr-link" records in the transcript
# (the input's .pr is only the current branch's open PR). OSC 8 links: label repo#N, cmd+click opens.
# ponytail: re-greps the transcript each render; cache by mtime if it ever lags on huge sessions.
transcript=$(echo "$input" | jq -r '.transcript_path // empty')
prs=()
[ -f "$transcript" ] && prs=(${(f)"$(grep -hF '"type":"pr-link"' "$transcript" \
  | jq -rs 'group_by(.prUrl) | map(.[0]) | sort_by(.timestamp) | .[] | "\(.prRepository | split("/") | last)#\(.prNumber) \(.prUrl)"' 2>/dev/null)"})
# Drop merged/closed PRs. State is cached per PR in $TMPDIR: MERGED/CLOSED are final (never re-checked);
# anything else is refreshed by a background `gh` at most every 5 min, so the render never waits on the network.
# ponytail: a reopened PR stays hidden until the cache is cleared (reboot or rm -r $PR_CACHE).
PR_CACHE="${TMPDIR:-/tmp}/claude-statusline-pr"; mkdir -p "$PR_CACHE"
unmerged=()
for p in $prs; do
  url=${p#* }; f="$PR_CACHE/${${url#https://github.com/}//\//_}"
  [[ -r $f && $(<$f) == (MERGED|CLOSED) ]] && continue
  fresh=($f(N.mm-5))
  if (( ! ${#fresh} )); then
    touch "$f"   # claims the refresh so concurrent renders don't spawn duplicates
    { gh pr view "$url" --json state -q .state > "$f.tmp" && mv "$f.tmp" "$f" } >/dev/null 2>&1 &!
  fi
  unmerged+=("$p")
done
prs=($unmerged)

MAX_PRS=5
links=()
if (( ${#prs} > MAX_PRS )); then
  links+=("${DIM}+$(( ${#prs} - MAX_PRS ))${RESET}")
  prs=("${(@)prs[-MAX_PRS,-1]}")
fi
for p in $prs; do
  links+=($'\e]8;;'"${p#* }"$'\e\\'"${MAGENTA}${p%% *}${RESET}"$'\e]8;;\e\\')
done
line3="${(j: :)links}"

printf '%s\n%s' "$line1" "$line2"
[ -n "$line3" ] && printf '\n%s%s' "${DIM}PRs${RESET} " "$line3"
exit 0
