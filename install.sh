#!/bin/sh
# This script installs my dotfiles + some extras into any Debian-based *nix system.

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

# Option to simply pipe to terminal for quicker install
if [ $# -ne 0 ]; then
  git clone https://github.com/abominox/dotfiles ~/.dotfiles
  cd ~/.dotfiles && ./install.sh

else
  # Rename old dotfiles and preserve them, if applicable.
  mkdir ~/.dotfiles_old
  cp -av ~/.vim ~/.dotfiles_old/.vim
  cp -av ~/.vimrc ~/.dotfiles_old/.vimrc
  cp -av ~/.tmux.conf ~/.dotfiles_old/.tmux.conf
  cp -av ~/.fonts ~/.dotfiles_old/.fonts.old
  cp -av ~/.bashrc ~/.dotfiles_old/.bashrc
  cp -av ~/.Xresources ~/.dotfiles_old/.Xresources
  cp -av ~/.bash_aliases ~/.dotfiles_old/.bash_aliases

  # Symlink new dotfiles into user home dir
  ln -fnvs "$(pwd)"/.vim ~/.vim
  ln -fnvs "$(pwd)"/.vimrc ~/.vimrc
  ln -fnvs "$(pwd)"/.tmux.conf ~/.tmux.conf
  ln -fnvs "$(pwd)"/.bashrc ~/.bashrc
  ln -fnvs "$(pwd)"/.Xresources ~/.Xresources
  ln -fnvs "$(pwd)"/.bash_aliases ~/.bash_aliases
  ln -fnvs "$(pwd)"/polybar/config ~/.config/polybar/config
  ln -fnvs "$(pwd)"/i3/config ~/.config/i3/config
fi
