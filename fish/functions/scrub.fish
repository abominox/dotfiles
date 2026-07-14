#!/usr/bin/env fish
# Delete lines with argument keyword from Fish history

function scrub -d "Delete lines with keyword from Fish history"
    set -l keyword $argv[1]

    if test -z "$keyword"
        echo "Usage: scrub <keyword>"
        return 1
    end

    # builtin history delete only supports --exact, so we search first
    # then delete each match by exact string.
    # Use --null with string split0 to handle entries containing newlines.
    # Trim each entry because history search may indent wrapped lines.
    set -l entries (builtin history search --contains "$keyword" --null | string split0 | string trim)

    if test -z "$entries[1]"
        echo "No entries found containing: $keyword"
        return 0
    end

    set -l count 0
    for entry in $entries
        if test -n "$entry"
            builtin history delete --exact --case-sensitive "$entry" 2>/dev/null
            set count (math $count + 1)
        end
    end

    # Persist deletions to the history file immediately
    builtin history save 2>/dev/null

    echo "Scrubbed $count entr"(test $count -eq 1; and echo "y"; or echo "ies")" containing: $keyword"
end