# custom transfer.sh alias
alias transfer='curl cjmarquart.com/script/transfer.sh | bash'

# Quickly download/convert YouTube videos to .mp3 using this alias + URL
alias yt2mp3="youtube-dl --extract-audio --audio-format mp3 --add-metadata \
--embed-thumbnail"

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

# If OS = MacOS then specify coreutils instead of BSD
if [ "$(uname -a | cut -d " " -f 1)" == "Darwin" ]
  then
    alias ls='ls --color=auto --group-directories-first -lh'
fi
