#!/usr/bin/env fish
# Custom title for terminal tabs/windows

function fish_title
    # Get full path, replace HOME with ~
    set -l current_dir (string replace -r "^$HOME" "~" -- $PWD)

    # If there's a running command, show it, otherwise just show the directory
    if set -q argv[1]
        echo $argv[1] - $current_dir
    else
        echo $current_dir
    end
end
