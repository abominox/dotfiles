#!/usr/bin/env fish
# Delete lines with argument keyword from Fish history

function scrub -d "Delete lines with keyword from Fish history"
    set -l keyword $argv[1]

    if test -z "$keyword"
        echo "Usage: scrub <keyword>"
        return 1
    end

    # Fish stores history in ~/.local/share/fish/fish_history
    set -l hist_file "$HOME/.local/share/fish/fish_history"

    if test -f "$hist_file"
        # Create temp file without matching entries
        grep -v "$keyword" "$hist_file" > "$hist_file.tmp"
        mv "$hist_file.tmp" "$hist_file"
        # Reload history
        history --merge
        echo "Scrubbed entries containing: $keyword"
    else
        echo "History file not found"
        return 1
    end
end
