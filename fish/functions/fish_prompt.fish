#!/usr/bin/env fish
# Custom prompt matching BASH PS1
# Format: [user@host path] $

function fish_prompt
    # Colors (exact BASH 256-color palette match)
    # Using tput to get exact terminal colors
    set -l gray (set_color 808080)    # Color 7 - gray for brackets
    set -l green (set_color 00ff00)   # Color 46 - bright green for user@host
    set -l blue (set_color 0087ff)    # Color 33 - blue for path
    set -l white (set_color normal)   # Reset to default
    set -l normal (set_color normal)

    # Get full path (like BASH \w), replace HOME with ~
    set -l current_dir (string replace -r "^$HOME" "~" -- $PWD)

    # Build prompt: [user@host path] $
    echo -n $gray'['$normal
    echo -n $green(whoami)'@'(prompt_hostname)$normal
    echo -n $white' '$normal
    echo -n $blue$current_dir$normal
    echo -n $gray']'$normal
    echo -n $white' '$normal
    echo -n $gray'$ '$normal
end
