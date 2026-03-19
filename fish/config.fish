#!/usr/bin/env fish
########## abominox's Fish shell configuration ##########

# This file is kept minimal - most config is in conf.d/
# Files in conf.d/ are automatically loaded by Fish

# ARM Homebrew environment setup (Apple Silicon only)
if test (uname -m) = "arm64"; and test -x /opt/homebrew/bin/brew
    eval (/opt/homebrew/bin/brew shellenv)
end

# Interactive shell setup
if status is-interactive

    # WSL2-specific settings
    if test -f /proc/sys/fs/binfmt_misc/WSLInterop
        set -x QT_QPA_PLATFORM wayland
    end

    # Disable welcome message
    set -g fish_greeting

    # Ignore commands starting with a space (like Bash)
    set -g fish_history_ignore_regex '^ '

	# Set cursor style
	set fish_cursor_default line

    # Clear "Last login" message for non-SSH sessions (macOS only)
    # Skip in VS Code terminal to avoid interfering with shell integration
    if test (uname -s) = "Darwin"
        if not set -q SSH_CONNECTION; and not set -q SSH_CLIENT; and not set -q VSCODE_INJECTION
            clear
        end
    end
end


# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
