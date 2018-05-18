#!/bin/bash
# This script installs my dotfiles into any *nix system.

# Install pre-reqs/dev-tools
sudo apt update && sudo apt install -y \
tmux \
vim \
python3 \
virtualenv \
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

# Delete old dotfiles
rm -Rf ~/.vim
rm -Rf ~/.fonts
sudo rm -f ~/.vimrc
sudo rm -f ~/.bashrc
sudo rm -f ~/.tmux.conf
sudo rm -f ~/.Xresources

# Symlink new dotfiles into user home dir
ln -vs ~/dotfiles/.vim ~/.vim
ln -vs ~/dotfiles/.vimrc ~/.vimrc
ln -vs ~/dotfiles/.tmux.conf ~/.tmux.conf
ln -vs ~/dotfiles/.fonts ~/.fonts
ln -vs ~/dotfiles/.bashrc ~/.bashrc
ln -vs ~/dotfiles/.Xresources ~/.Xresources
