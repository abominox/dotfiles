#!/usr/bin/env fish
### Environment Variables ###

# Set vim to default editor
set -gx EDITOR vim

# Set US UTF-8
set -gx LANG en_US.UTF-8

# Stop the new mail notifications in my terminals
set -gx MAILCHECK 0

# Enable colored prompt
set -gx force_color_prompt yes

# Include home bin folder in PATH
# Use fish_add_path if available (Fish 3.2+), otherwise fallback
if functions -q fish_add_path
    fish_add_path "$HOME/.local/bin"
else
    set -gx PATH "$HOME/.local/bin" $PATH
end

### Development ###

## C ##
# Set default GCC flags
set -gx CFLAGS "-Wall"
