#!/bin/bash
# This script installs my dotfiles into any *nix system, where applicable.

# Install pre-reqs/dev-tools
sudo apt update && sudo apt install -y \
tmux \
vim \
python3 \
pylint3 \
virtualenv \
python3-pip

# Install linters
pip3 install pylint

# Rename old dotfiles and preserve them, if applicable.
#mkdir ~/.dotfiles_old
#mv ~/.vim ~/.dotfiles_old/.vim
#mv ~/.vimrc ~/.dotfiles_old/.vimrc
#mv ~/.tmux.conf ~/.dotfiles_old/.tmux.conf
#mv ~/.fonts ~/.dotfiles_old/.fonts.old
#mv ~/.bashrc ~/.dotfiles_old/.bashrc

# Symlink new dotfiles into user home dir
ln -s dotfiles/.vim ~/.vim
ln -s dotfiles/.vimrc ~/.vimrc
ln -s dotfiles/.tmux.conf ~/.tmux.conf
ln -s dotfiles/.fonts ~/.fonts
ln -s dotfiles/.bashrc ~/.bashrc
