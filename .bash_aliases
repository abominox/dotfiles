########## abominox's .bash_aliases file ##########

####### Scripts #######

# Easy speedtest from the CLI
alias speedtest='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -'

# Alias to re-encode videos of given extension in current directory (append extension)
alias recode="curl -Ls https://raw.githubusercontent.com/abominox/assorted/master/scripts/recode.sh | source /dev/stdin"

# Custom transfer.sh alias
alias transfer='curl -s cjmarquart.com/script/transfer.sh | bash'

####### tmux #######

# Force tmux to assume terminal supports 256 colors
alias tmux='tmux -2'

# Quickly re-attach detached tmux sessions
alias ta='tmux a -t'

# Quickly see open tmux sessions
alias tls='tmux ls'

####### Python #######

# Force Python 2 to be Python 3
alias python=python3

# Activate virtualenv easier
alias activate="source env/bin/activate"

# Force pip2 to be pip3
alias pip=pip3

####### Misc #######

# Quickly download/convert YouTube videos to .mp3 using this alias + URL
alias yt2mp3="youtube-dl --ignore-errors --extract-audio --audio-format mp3 --add-metadata \
--embed-thumbnail -o '%(title)s.%(ext)s'"

# Force better ytdl output name for any downloaded file
alias youtube-dl="youtube-dl --ignore-errors -o '%(title)s.%(ext)s'"

# Preserve environment during sudo
alias sudo='sudo -E'

# Safer alias for rm
alias rm='rm -i'

# Default ls to format better
alias ls='ls --color=auto --group-directories-first -lh'

# Colored grep output
alias grep='grep --color=auto'

# For when you forget to add "sudo"
alias fuck='sudo $(history -p \!\!)'

# wget aliases for open-directory hunting, append desired pattern (*.pdf, etc.) + address
alias vacuum='wget -nd -N -r -e robots=off -P . --no-parent --reject "index.html*" -A'
alias vacuum-folder='wget -N -r -e robots=off -P . --no-parent --reject "index.html*" -A'

# Easily find commands in Bash history
alias sherlock='history | grep'
