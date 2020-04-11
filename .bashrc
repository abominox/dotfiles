########## abominox's .bashrc file ##########

### HISTORY ###

# Prepend date/time before commands in .bash_history
export HISTTIMEFORMAT='%D %r --> '

# Set .bash_history to ignore common commands
export HISTIGNORE='clear:ls:fuck:sherlock *'

# After each command, save and reload history. Enables commands
# from a tmux buffer to save into .bash_history
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

# don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=-1
HISTFILESIZE=-1

# append to the history file, don't overwrite it
shopt -s histappend

### TERMINAL ###

# Set US UTF-8
LANG='en_US.UTF-8'

# Stop the new mail notifications in my terminals
MAILCHECK=0

# Force full color support for terminal
TERM=xterm-256color

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Enable colored prompt
force_color_prompt=yes
    
# custom PS1 prompt
PS1="\[\033[38;5;7m\][\[$(tput sgr0)\]\[\033[38;5;46m\]\u@\h\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]\[\033[38;5;33m\]\w\[$(tput sgr0)\]\[\033[38;5;7m\]]\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]\[\033[38;5;7m\]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"

# Enable separate ".bash_aliases" file
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# If MacOS, specify coreutils instead of BSD
if [ "$(uname -a | cut -d " " -f 1)" == "Darwin" ]; then
    alias ls='gls --color=auto --group-directories-first -lh'
fi
