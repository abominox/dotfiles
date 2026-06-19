#!/usr/bin/env fish
# For when you forget to add "sudo"

function fuck -d "Run last command with sudo"
    # Use fish -c to avoid re-evaluating command substitutions in sudo context
    sudo fish -c (string escape -- $history[1])
end
