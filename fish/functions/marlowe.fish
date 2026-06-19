#!/usr/bin/env fish
# Easily find alias or function in Fish configuration

function marlowe -d "Search Fish aliases and functions"
    # Resolve dotfiles path dynamically (follows symlinks)
    set -l fish_dir (dirname (realpath (status filename)))/../..
    # Search in Fish config files for alias/function definitions
    grep -h -i "$argv" $fish_dir/conf.d/*.fish $fish_dir/functions/*.fish 2>/dev/null | grep -v "^#"
end
