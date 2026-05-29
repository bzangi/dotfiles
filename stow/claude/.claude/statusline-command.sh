#!/usr/bin/env zsh

input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')

# Resolve git repo name and relative path (mirrors refined theme's vcs_info %r/%S)
git_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
if [ -n "$git_root" ]; then
  repo_name=$(basename "$git_root")
  rel_path="${cwd#$git_root}"
  rel_path="${rel_path#/}"
  if [ -n "$rel_path" ]; then
    display_path="${repo_name}/${rel_path}"
  else
    display_path="${repo_name}"
  fi

  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  dirty=$(git -C "$cwd" diff --quiet --ignore-submodules HEAD 2>/dev/null; [ $? -eq 1 ] && echo "*")
  git_info=" ${branch}${dirty}"
else
  display_path=$(echo "$cwd" | sed "s|^$HOME|~|")
  git_info=""
fi

model=$(echo "$input" | jq -r '.model.display_name // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

ctx_info=""
if [ -n "$used" ]; then
  ctx_info=" · ctx $(printf '%.0f' "$used")%"
fi

model_info=""
if [ -n "$model" ]; then
  model_info=" · ${model}"
fi

printf "\033[34m%s\033[0m\033[2m%s%s%s\033[0m" "$display_path" "$git_info" "$model_info" "$ctx_info"
