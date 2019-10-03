#!/bin/bash
# This script installs my dotfiles + some extras into any *nix system.
# Requires Bash. Full install requires apt.

dotfiles=(
  .vim
  .vimrc
  .tmux.conf
  .fonts
  .bashrc
  .Xresources
  .bash_aliases
  .profile
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
  python3-pip

  # Install linters
  sudo pip3 install pylint
}

install_dotfiles () {
  for dotfile in "${dotfiles[@]}"
  do
    # Preserve old dotfiles, if applicable
    if [ -f "$dotfile" ]; then
      echo "Existing dotfiles are being moved to ~/.dotfiles_old"
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
