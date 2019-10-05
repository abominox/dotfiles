# custom transfer.sh alias
alias transfer='curl -s cjmarquart.com/script/transfer.sh | bash'

# Quickly download/convert YouTube videos to .mp3 using this alias + URL
alias yt2mp3="youtube-dl --ignore-errors --extract-audio --audio-format mp3 --add-metadata \
--embed-thumbnail -o '%(title)s.%(ext)s'"

# Force better ytdl output name for any downloaded file
alias youtube-dl="youtube-dl --ignore-errors -o '%(title)s.%(ext)s'"

# Preserve environment during sudo
alias sudo='sudo -E'

# Safer alias for rm
alias rm='rm -i'

# Automatically forward public keyring
#alias ssh='ssh -A'

# Default ls to format better
alias ls='ls --color=auto --group-directories-first -lh'

# Force tmux to assume terminal supports 256 colors
alias tmux='tmux -2'

# Force Python 2 to be Python 3
alias python=python3

# Activate virtualenv easier
alias activate="source env/bin/activate"

# Force pip2 to be pip3
alias pip=pip3

# For when you forget to add "sudo"
alias fuck='sudo $(history -p \!\!)'

# Easy speedtest from the CLI
alias speedtest='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -'

# wget aliases for open-directory hunting, append desired pattern (*.pdf, etc.) + address
alias vacuum='wget -nd -N -r -e robots=off -P . --no-parent --reject "index.html*" -A'
alias vacuum-folder='wget -N -r -e robots=off -P . --no-parent --reject "index.html*" -A'

# Alias to re-encode videos of given extension in current directory (append extension)
alias recode="curl -Ls http://bit.ly/31L4NtQ | bash"
