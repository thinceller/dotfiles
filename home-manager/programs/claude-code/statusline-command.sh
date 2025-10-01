#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract information from JSON
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model_name=$(echo "$input" | jq -r '.model.display_name // "Unknown Model"')

# Get git branch if we're in a git repository
git_branch=""
if [ -d "$current_dir/.git" ] || git -C "$current_dir" rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git -C "$current_dir" branch --show-current 2>/dev/null)
    if [ -n "$branch" ]; then
        git_branch=" on $branch"
    fi
fi

# Get relative path for better readability
if [[ "$current_dir" == "$HOME"* ]]; then
    display_dir="~${current_dir#$HOME}"
else
    display_dir="$current_dir"
fi


# Format the status line with colors
printf "\033[36m%s\033[0m\033[32m%s\033[0m \033[2m|\033[0m \033[35m%s\033[0m" \
    "$display_dir" "$git_branch" "$model_name"