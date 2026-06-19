#!/usr/bin/env fish
# Delete lines with argument keyword from Fish history

function scrub -d "Delete lines with keyword from Fish history"
    set -l keyword $argv[1]

    if test -z "$keyword"
        echo "Usage: scrub <keyword>"
        return 1
    end

    # Use builtin history delete — safe, concurrent, no file editing
    builtin history delete --contains "$keyword"
    echo "Scrubbed entries containing: $keyword"
end
