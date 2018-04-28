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
mkdir ~/.dotfiles_old
mv -v ~/.vim ~/.dotfiles_old/.vim
mv -v ~/.vimrc ~/.dotfiles_old/.vimrc
mv -v ~/.tmux.conf ~/.dotfiles_old/.tmux.conf
mv -v ~/.fonts ~/.dotfiles_old/.fonts.old
mv -v ~/.bashrc ~/.dotfiles_old/.bashrc

# Symlink new dotfiles into user home dir
ln -vs .vim ~/.vim
ln -vs .vimrc ~/.vimrc
ln -vs .tmux.conf ~/.tmux.conf
ln -vs .fonts ~/.fonts
ln -vs .bashrc ~/.bashrc
