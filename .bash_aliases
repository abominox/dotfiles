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
#alias python=python3

# Activate virtualenv easier
alias activate="source .env/bin/activate 2>/dev/null || source env/bin/activate"

# Easily create virtualenv
alias venv="virtualenv -p python3 .env"

# Force pip2 to be pip3
#alias pip=pip3

# Quick n' Easy HTTP Server on current directory
alias server="python3 -m http.server"

# Use pipreqs instead of pip freeze and avoid incl. global packages
alias pf="pipreqs --use-local ."

###### JavaScript ######

# Install Node Version Manager
alias nvm-install="curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash" 

###### White Hat ######

# Shorter Metasploit command
alias msf="msfconsole || /opt/metasploit-framework/bin/msfconsole"

####### Misc #######

# Quickly download/convert YouTube videos to .mp3 using this alias + URL
alias yt2mp3="youtube-dl --ignore-errors --extract-audio --audio-format mp3 --add-metadata \
--embed-thumbnail -o '%(title)s.%(ext)s'"

# Force better ytdl output name for any downloaded file
alias youtube-dl="youtube-dl --ignore-errors -o '%(title)s.%(ext)s'"

# Safer alias for rm
alias rm='rm -i'

# Find external IP address
alias whatismyip='dig +short myip.opendns.com @resolver1.opendns.com'

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

# Easily find alias in this file
alias marlowe='cat ~/.dotfiles/.bash_aliases | grep'

# Test nginx conf and restart service if successful
alias ntest="sudo nginx -t && sudo service nginx restart && sudo service nginx status"

# Delete lines with argument keyword from Bash history
scrub() { sed -i "/$1/d" /home/"$(whoami)"/.bash_history; }

# Easy SSH to my homelab
alias home="ssh -A raxemremy@cjmarquart.com"

# Easily search cheat.sh from the terminal
#alias cheat="curl cheat.sh/"

# Cleanup orphaned dependencies (Pacman)
orph() { sudo pacman -R "$(pacman -Qdtq)"; }
