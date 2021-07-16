#!/bin/bash
# This script installs my dotfiles + some extras into any *nix system.
# Requires Bash. Full install requires apt.

dotfiles=(
  .vim
  .vimrc
  .tmux.conf
  .tmux
  .fonts
  .bashrc
  .Xresources
  .bash_aliases
  .profile
  .Xauthority
)

install_devtools () {
  # Install pre-reqs/dev-tools
  sudo apt update && sudo apt install -y \
  tmux \
  vim \
  git \
  curl \
  htop \
  ncdu \
  net-tools \
  python3 \
  virtualenv \
  shellcheck \
  python3-pip \
  jq

  # Install linters, etc.
  pip3 install \
  pylint \
  psutil \
  requests
}

install_dotfiles () {
  for dotfile in "${dotfiles[@]}"
  do
    # Preserve old dotfiles, if applicable
    if [ -f "$dotfile" ]; then
      mkdir -p ~/.dotfiles_old
      cp -av ~/"$dotfile" ~/.dotfiles_old/"$dotfile"
    fi

    # Symlink new dotfiles into user home dir
    ln -fnvs "$(pwd)"/"$dotfile" ~/"$dotfile"
  done
}

if [ "$1" = "minimal" ]
then
  install_dotfiles
else
  install_devtools
  install_dotfiles
fi
