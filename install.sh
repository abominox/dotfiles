#!/bin/bash
# This script installs my dotfiles into any *nix system.

# Install pre-reqs/dev-tools
sudo apt update && sudo apt install -y \
tmux \
vim \
python3 \
virtualenv \
thefuck /
python3-pip

# Install linters
sudo pip3 install pylint

# Rename old dotfiles and preserve them, if applicable.
mkdir ~/.dotfiles_old
cp -av ~/.vim ~/.dotfiles_old/.vim
cp -av ~/.vimrc ~/.dotfiles_old/.vimrc
cp -av ~/.tmux.conf ~/.dotfiles_old/.tmux.conf
cp -av ~/.fonts ~/.dotfiles_old/.fonts.old
cp -av ~/.bashrc ~/.dotfiles_old/.bashrc
cp -av ~/.Xresources ~/.dotfiles_old/.Xresources

# Delete old dotfiles
rm -Rf ~/.vim
rm -Rf ~/.fonts
sudo rm -f ~/.vimrc
sudo rm -f ~/.bashrc
sudo rm -f ~/.tmux.conf
sudo rm -f ~/.Xresources

# Symlink new dotfiles into user home dir
ln -vs $(pwd)/.vim ~/.vim
ln -vs $(pwd)/.vimrc ~/.vimrc
ln -vs $(pwd)/.tmux.conf ~/.tmux.conf
ln -vs $(pwd)/.fonts ~/.fonts
ln -vs $(pwd)/.bashrc ~/.bashrc
ln -vs $(pwd)/.Xresources ~/.Xresources
ln -vs $(pwd)/polybar/config ~/.config/polybar/config
ln -vs $(pwd)/i3/config ~/.config/i3/config
