if [ -r ~/.bashrc ]; then
   source ~/.bashrc
fi

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
