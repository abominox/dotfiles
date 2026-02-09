#!/usr/bin/env fish
# Easily find alias or function in Fish configuration

function marlowe -d "Search Fish aliases and functions"
    # Search in Fish config files for alias/function definitions
    grep -h -i "$argv" ~/.dotfiles/fish/conf.d/*.fish ~/.dotfiles/fish/functions/*.fish 2>/dev/null | grep -v "^#"
end
