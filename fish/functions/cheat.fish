#!/usr/bin/env fish
# Easily search cheat.sh from the terminal

function cheat -d "Query cheat.sh from terminal"
    curl cheat.sh/$argv
end
