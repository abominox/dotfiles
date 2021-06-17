########## abominox's .bashrc file ##########

### HISTORY ###

# Prepend date/time before commands in .bash_history
export HISTTIMEFORMAT='%D %r --> '

# Set .bash_history to ignore common commands
export HISTIGNORE='clear:claer:history:ls:fuck:tls:ta *:sherlock *'

# After each command, save and reload history. Enables commands
# from a tmux buffer to save into .bash_history
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

# don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

### TERMINAL ###

# Set vim to default editor
export EDITOR=vim

# Set US UTF-8
LANG='en_US.UTF-8'

# Stop the new mail notifications in my terminals
MAILCHECK=0

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Enable colored prompt
force_color_prompt=yes
    
# custom PS1 prompt
PS1="\[\033[38;5;7m\][\[$(tput sgr0)\]\[\033[38;5;46m\]\u@\h\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]\[\033[38;5;33m\]\w\[$(tput sgr0)\]\[\033[38;5;7m\]]\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]\[\033[38;5;7m\]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"

# Enable separate ".bash_aliases" file, if applicable
if [ -f ~/.bash_aliases ]; then
    source ~/.bash_aliases
fi

# If dotenv file exists, use it
if [ -f ~/.env ]; then
    source ~/.env
fi

## Development ##
# Set GOPATH
export PATH="$PATH:~/.go/bin"


PLATFORM=$(uname -a | cut -d " " -f 1)
## Linux ##
if [ "$PLATFORM" == "Linux" ]; then
    # Force full color support for terminal
    TERM=tmux-256color

    # Fix problems with PROMPT_COMMAND in newer vers.
    unset PROMPT_COMMAND
    export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

    # for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
    export HISTSIZE=-1
    export HISTFILESIZE=-1

### MacOS ###
elif [ "$PLATFORM" == "Darwin" ]; then
    # Force full color support for terminal
    TERM=xterm-256color

    # Specify coreutils for some things instead of BSD
    alias ls='gls --color=auto --group-directories-first -lh'
    alias date='gdate'

    # Add pip to PATH
    export PATH="$PATH:/Library/Frameworks/Python.framework/Versions/3.9/bin"

    # Supress new ZSH default message
    export BASH_SILENCE_DEPRECATION_WARNING=1

    # Make Bash history work
    export SHELL_SESSION_HISTORY=0
    export HISTFILE=/Users/$(echo $USER)/.bash_history
    export HISTSIZE=10000000
fi

