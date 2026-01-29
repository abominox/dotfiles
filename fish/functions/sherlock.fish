#!/usr/bin/env fish
# Easily find commands in Fish history

function sherlock -d "Search command history"
    history | grep -i $argv
end
