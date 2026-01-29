#!/usr/bin/env fish
# Cleanup orphaned dependencies (Pacman)

function orph -d "Cleanup orphaned dependencies (Pacman)"
    set -l orphans (pacman -Qdtq 2>/dev/null)

    if test -n "$orphans"
        sudo pacman -R $orphans
    else
        echo "No orphaned packages found"
    end
end
