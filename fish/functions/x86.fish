#!/usr/bin/env fish
# Easily run things in Rosetta compatibility layer on M1

function x86 -d "Run command via Rosetta on M1 Macs"
    arch -x86_64 /bin/bash -c "$argv"
end
