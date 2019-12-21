#### PATH
## GOLANG
if [ -d "/usr/local/go" ]; then
  export PATH=$PATH:/usr/local/go/bin
fi

## Flutter
if [ -d "/usr/local/flutter" ]; then
  export PATH=$PATH:/usr/local/flutter/bin
fi

#### MISC
# Pushbullet API Key
if [ -f "$HOME"/.dotfiles/.pb_key ]; then
  source "$HOME"/.dotfiles/.pb_key
fi

# default editor
EDITOR="vim"

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi
