#!/usr/bin/env fish
# Easily find alias or function in Fish configuration

function marlowe -d "Search Fish aliases and functions"
    # Search in both aliases and functions
    begin
        alias | grep -i $argv
        functions -n | grep -i $argv
    end
end
