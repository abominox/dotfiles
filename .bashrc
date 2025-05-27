#!/bin/bash
########## abominox's .bashrc file ##########

### HISTORY ###

# Prepend date/time before commands in .bash_history
export HISTTIMEFORMAT='%D %r --> '

# Set .bash_history to ignore common commands
export HISTIGNORE='clear:claer:w:scrub *:history:ls:fuck:tls:ta *:sherlock *'

# After each command, save and reload history. Enables commands
# from a tmux buffer to save into .bash_history
export PROMPT_COMMAND="history -a; history -c; history -r"

# don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth

# Append to the history file, don't overwrite it
shopt -s histappend

### TERMINAL ###

# Set vim to default editor
export EDITOR=vim

# Set US UTF-8
LANG='en_US.UTF-8'

# Stop the new mail notifications in my terminals
MAILCHECK=0

# Include home bin folder in PATH
export PATH="$PATH:/home/$(whoami)/.local/bin"

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Enable colored prompt
export force_color_prompt=yes
    
# custom PS1 prompt
PS1="\[\033[38;5;7m\][\[\033[0m\]\[\033[38;5;46m\]\u@\h\[\033[0m\]\[\033[38;5;15m\] \[\033[0m\]\[\033[38;5;33m\]\w\[\033[0m\]\[\033[38;5;7m\]]\[\033[0m\]\[\033[38;5;15m\] \[\033[0m\]\[\033[38;5;7m\]\\$\[\033[0m\]\[\033[38;5;15m\] \[\033[0m\]"

# Enable separate ".bash_aliases" file, if applicable
if [ -f ~/.bash_aliases ]; then
    source ~/.bash_aliases
fi

# If dotenv file exists, use it
if [ -f ~/.env ]; then
    source ~/.env
fi

### Development ###

## C ##
# Set default GCC flags
export CFLAGS="-Wall"

### Platform ###
PLATFORM=$(uname -a | cut -d " " -f 1)

## Linux ##
if [ "$PLATFORM" = "Linux" ]; then
    # for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
    export HISTSIZE=-1
    export HISTFILESIZE=-1

	## Golang ##	
	# Set GOPATH
    GOUSER=$(whoami)
    export GOPATH="/home/${GOUSER}/projects/go"
    export PATH="$PATH:/home/${GOUSER}/projects/go/bin"


## MacOS ##
elif [ "$PLATFORM" = "Darwin" ]; then
    # Force full color support for terminal
    TERM=xterm-256color

    # Specify coreutils for some things instead of BSD
    alias ls='gls --color=auto --group-directories-first -lh'
    alias date='gdate'

    # Add pip to PATH
    export PATH="$PATH:/Library/Frameworks/Python.framework/Versions/3.9/bin"

	# Fix Python 3.9 packages PATH
	export PATH="$PATH:/usr/local/lib/python3.9/site-packages"

	# Add GNU coreutils to PATH, to enable regular names (no 'g' prefix)
	export PATH="$PATH:/usr/local/opt/coreutils/libexec/gnubin"

    # Add VS Code to PATH
    export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

    # Supress new ZSH default message
    export BASH_SILENCE_DEPRECATION_WARNING=1

    # Make Bash history work
    export SHELL_SESSION_HISTORY=0
    HISTFILE_PATH="/Users/$USER/.bash_history"
    export HISTFILE="$HISTFILE_PATH"
    export HISTSIZE=10000000

    # Enable systat on the tmux statusline
    nohup bash ~/.dotfiles/scripts/systat.sh > /dev/null 2>&1

	## Golang ##
	# Set GOPATH
	export GOPATH="/Users/$(whoami)/projects/go"
	export PATH="$PATH:/Users/$(whoami)/projects/go/bin"
fi

## NT ##
if [ "$(uname -a | grep WSL)" ]; then
    # Support X11 forwarding in WSL2
    export DISPLAY="$(awk '/nameserver / {print $2; exit}' /etc/resolv.conf 2>/dev/null):0"
    export LIBGL_ALWAYS_INDIRECT=1

	## Golang ##
    # Set GOPATH
    export GOPATH="/home/$(whoami)/projects/go"
	export PATH="/usr/local/go/bin:$PATH"

fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
