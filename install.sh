#!/bin/bash
# This script installs my dotfiles + some extras into any *nix system.
# Requires Bash. Full install requires apt.

dotfiles=(
  .vim
  .vimrc
  .tmux.conf
  .tmux
  .fonts
  .Xresources
  .Xauthority
)

# Fish shell configuration directory
fish_config_dir="$HOME/.config/fish"

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
  jq \
  fish

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

  # Install Fish configuration
  install_fish_config
}

install_fish_config () {
  echo "Setting up Fish shell configuration..."

  # Create Fish config directory if it doesn't exist
  mkdir -p "$fish_config_dir"
  mkdir -p "$fish_config_dir/conf.d"
  mkdir -p "$fish_config_dir/functions"
  mkdir -p "$fish_config_dir/completions"

  # Backup existing Fish config
  if [ -f "$fish_config_dir/config.fish" ]; then
    mkdir -p ~/.dotfiles_old/fish
    cp -av "$fish_config_dir"/* ~/.dotfiles_old/fish/ 2>/dev/null || true
  fi

  # Symlink Fish configuration
  ln -fnvs "$(pwd)/fish/config.fish" "$fish_config_dir/config.fish"

  # Symlink conf.d files
  for conf_file in "$(pwd)"/fish/conf.d/*.fish; do
    [ -f "$conf_file" ] || continue
    ln -fnvs "$conf_file" "$fish_config_dir/conf.d/$(basename "$conf_file")"
  done

  # Symlink functions
  for func_file in "$(pwd)"/fish/functions/*.fish; do
    [ -f "$func_file" ] || continue
    ln -fnvs "$func_file" "$fish_config_dir/functions/$(basename "$func_file")"
  done

  echo "Fish configuration installed!"
  echo "To set Fish as default shell, run: chsh -s \$(which fish)"
}

if [ "$1" = "minimal" ]
then
  install_dotfiles
else
  install_devtools
  install_dotfiles
fi
