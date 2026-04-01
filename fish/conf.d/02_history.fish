#!/usr/bin/env fish
### History configuration ###

# Avoid duplicates in history (equivalent to HISTCONTROL=ignoreboth)
set -gx fish_history_avoid_duplicates yes

# Don't save commands starting with space (fish has no native support, so we delete after the fact)
function __history_ignore_space --on-event fish_preexec
    if string match -qr '^ ' -- "$argv"
        builtin history delete --case-sensitive --exact -- "$argv"
        builtin history delete --case-sensitive --exact -- (string trim -- "$argv")
    end
end

# Fish automatically timestamps history and syncs across sessions!
# No additional configuration needed for:
# - HISTTIMEFORMAT (Fish always timestamps history entries)
# - PROMPT_COMMAND history syncing (Fish does this automatically)
# - History file appending (Fish handles this natively)

# Note: HISTIGNORE is not directly supported in Fish
# Fish's superior history search makes this less necessary
# Use the 'scrub' function to delete unwanted history entries after the fact
