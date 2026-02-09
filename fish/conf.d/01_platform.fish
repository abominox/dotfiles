#!/usr/bin/env fish
### Platform-specific configuration ###

# Helper function for backwards compatibility with Fish < 3.2
function __add_path
    if functions -q fish_add_path
        fish_add_path $argv
    else if not contains $argv[1] $PATH
        set -gx PATH $argv[1] $PATH
    end
end

# Platform detection using uname
switch (uname -s)
    case Darwin
        ### macOS-specific settings ###

        # Force full color support for terminal
        set -gx TERM xterm-256color

        # Specify coreutils for some things instead of BSD
        # Use eza if available, otherwise gls
        if command -v eza &> /dev/null
            alias ls='eza -lh --group-directories-first --icons'
        else
            alias ls='gls --color=auto --group-directories-first -lh'
        end
        alias date='gdate'

        # Add pip to PATH
        __add_path /Library/Frameworks/Python.framework/Versions/3.9/bin

        # Fix Python 3.9 packages PATH
        __add_path /usr/local/lib/python3.9/site-packages

        # Add GNU coreutils to PATH, to enable regular names (no 'g' prefix)
        __add_path /usr/local/opt/coreutils/libexec/gnubin

        # Add VS Code to PATH
        __add_path "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

        # Suppress new ZSH default message
        set -gx BASH_SILENCE_DEPRECATION_WARNING 1

        # Make Fish history work properly on macOS
        set -gx HISTFILE "$HOME/.local/share/fish/fish_history"
        set -gx fish_history_max_items 10000000

        # Golang
        set -gx GOPATH "$HOME/projects/go"
        __add_path "$GOPATH/bin"

    case Linux
        ### Linux-specific settings ###

        # Unlimited history on Linux
        set -gx fish_history_max_items -1

        # Golang
        set -gx GOPATH "$HOME/projects/go"
        __add_path "$GOPATH/bin"

        # Check for WSL2 (using ; and for Fish < 3.0 compatibility)
        if test -f /proc/version; and string match -q '*microsoft*' (cat /proc/version)
            ### WSL2-specific settings ###

            # Support X11 forwarding in WSL2
            set -l display_ip (awk '/nameserver / {print $2; exit}' /etc/resolv.conf 2>/dev/null)
            set -gx DISPLAY "$display_ip:0"
            set -gx LIBGL_ALWAYS_INDIRECT 1

            # Go toolchain (WSL2 installs Go to /usr/local)
            __add_path /usr/local/go/bin
        end
end
