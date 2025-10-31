#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract information from JSON
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model_name=$(echo "$input" | jq -r '.model.display_name // "Unknown Model"')
transcript_path=$(echo "$input" | jq -r '.transcript_path // ""')
model_id=$(echo "$input" | jq -r '.model.id // ""')

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

# Get context usage percentage
context_percentage=""
context_color=""
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
    # Get the last assistant message with usage info
    usage_json=$(grep '"type":"assistant"' "$transcript_path" | tail -1 | jq -c '.message.usage // empty' 2>/dev/null)

    if [ -n "$usage_json" ]; then
        # Extract token counts
        input_tokens=$(echo "$usage_json" | jq -r '.input_tokens // 0')
        cache_creation_tokens=$(echo "$usage_json" | jq -r '.cache_creation_input_tokens // 0')
        cache_read_tokens=$(echo "$usage_json" | jq -r '.cache_read_input_tokens // 0')

        # Calculate total input tokens
        total_tokens=$((input_tokens + cache_creation_tokens + cache_read_tokens))

        # Determine context limit based on model (default: 200K for Claude Sonnet 4.5)
        context_limit=200000

        # Calculate percentage (using bc for floating point)
        if command -v bc >/dev/null 2>&1; then
            context_percentage=$(echo "scale=1; $total_tokens * 100 / $context_limit" | bc)

            # Determine color code based on percentage
            if (( $(echo "$context_percentage < 50" | bc -l) )); then
                context_color="32"  # Green
            elif (( $(echo "$context_percentage < 80" | bc -l) )); then
                context_color="33"  # Yellow
            else
                context_color="31"  # Red
            fi
        fi
    fi
fi

# Format the status line with colors
if [ -n "$context_percentage" ]; then
    printf "\033[36m%s\033[0m\033[32m%s\033[0m \033[2m|\033[0m \033[35m%s\033[0m \033[2m|\033[0m \033[%sm%s%%\033[0m" \
        "$display_dir" "$git_branch" "$model_name" "$context_color" "$context_percentage"
else
    printf "\033[36m%s\033[0m\033[32m%s\033[0m \033[2m|\033[0m \033[35m%s\033[0m" \
        "$display_dir" "$git_branch" "$model_name"
fi
