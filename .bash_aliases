# custom transfer.sh alias
alias transfer='curl cjmarquart.com/script/transfer.sh | bash'

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
alias ssh='ssh -A'

# Default ls to format better
alias ls='ls --color=auto --group-directories-first -lh'

# Force tmux to assume terminal supports 256 colors
alias tmux='tmux -2'

# Force Python 2 to be Python 3
alias python=python3

# Force pip2 to be pip3
alias pip=pip3
