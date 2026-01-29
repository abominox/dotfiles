#!/usr/bin/env fish
# For when you forget to add "sudo"

function fuck -d "Run last command with sudo"
    eval sudo $history[1]
end
