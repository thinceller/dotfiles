#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract information from JSON
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model_name=$(echo "$input" | jq -r '.model.display_name // "Unknown Model"')

# Extract context window information
CONTEXT_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
USAGE=$(echo "$input" | jq '.context_window.current_usage')

# Get git branch if we're in a git repository
git_branch=""
if [ -d "$current_dir/.git" ] || git -C "$current_dir" rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git -C "$current_dir" branch --show-current 2>/dev/null)
    if [ -n "$branch" ]; then
        git_branch=" 🌿 $branch"
    fi
fi

# Get relative path for better readability
if [[ "$current_dir" == "$HOME"* ]]; then
    display_dir="~${current_dir#$HOME}"
else
    display_dir="$current_dir"
fi

# Get context usage percentage
if [ "$USAGE" != "null" ]; then
    CURRENT_TOKENS=$(echo "$USAGE" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
    context_percentage=$((CURRENT_TOKENS * 100 / CONTEXT_SIZE))

    # Determine color code based on percentage
    if [ "$context_percentage" -lt 50 ]; then
        context_color="32"  # Green
    elif [ "$context_percentage" -lt 80 ]; then
        context_color="33"  # Yellow
    else
        context_color="31"  # Red
    fi
else
    context_percentage=0
    context_color="32"  # Green for 0%
fi

# Format the status line with colors and emojis (always show context percentage)
printf "📁 \033[36m%s\033[0m\033[32m%s\033[0m \033[2m|\033[0m 🤖 \033[35m%s\033[0m \033[2m|\033[0m \033[%sm📊 Context: %s%%\033[0m" \
    "$display_dir" "$git_branch" "$model_name" "$context_color" "$context_percentage"
