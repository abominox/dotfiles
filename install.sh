#!/bin/bash
# This script installs my dotfiles + some extras into any *nix system.
# Requires Bash. Supports macOS (brew), Debian/Ubuntu (apt), and Arch Linux (pacman).

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

# Detect platform and package manager
detect_platform () {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macos"
  elif [ -f /etc/arch-release ]; then
    echo "arch"
  elif [ -f /etc/debian_version ]; then
    echo "debian"
  else
    echo "unknown"
  fi
}

install_devtools () {
  local platform
  platform=$(detect_platform)

  echo "Detected platform: $platform"

  case "$platform" in
    macos)
      # Check if Homebrew is installed
      if ! command -v brew &> /dev/null; then
        echo "Homebrew not found. Installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      fi

      brew install \
        tmux \
        vim \
        git \
        curl \
        htop \
        ncdu \
        python3 \
        shellcheck \
        jq \
        fish \
        eza \
        coreutils

      brew install --cask font-jetbrains-mono-nerd-font
      ;;

    debian)
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

      # eza requires a separate installation on Debian
      if ! command -v eza &> /dev/null; then
        sudo mkdir -p /etc/apt/keyrings
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
        sudo apt update && sudo apt install -y eza
      fi
      ;;

    arch)
      sudo pacman -Syu --noconfirm \
        tmux \
        vim \
        git \
        curl \
        htop \
        ncdu \
        net-tools \
        python \
        python-virtualenv \
        shellcheck \
        python-pip \
        jq \
        fish \
        eza
      ;;

    *)
      echo "Unknown platform. Please install packages manually."
      return 1
      ;;
  esac

  # Install Python linters (cross-platform)
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

  # Install Ghostty configuration (macOS only)
  install_ghostty_config

  # Install WSL2 configuration if applicable
  install_wsl_config
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

install_ghostty_config () {
  # Only install on macOS
  if [[ "$(detect_platform)" != "macos" ]]; then
    return 0
  fi

  local ghostty_dir="$HOME/Library/Application Support/com.mitchellh.ghostty"
  echo "Setting up Ghostty configuration..."

  mkdir -p "$ghostty_dir"

  # Backup existing config if it's not already a symlink to our dotfiles
  if [ -f "$ghostty_dir/config" ] && [ ! -L "$ghostty_dir/config" ]; then
    mkdir -p ~/.dotfiles_old/ghostty
    cp -av "$ghostty_dir/config" ~/.dotfiles_old/ghostty/config
  fi

  ln -fnvs "$(pwd)/ghostty/config" "$ghostty_dir/config"
  echo "Ghostty configuration installed!"
}

install_wsl_config () {
  # Only install on WSL2 instances
  if grep -qi microsoft /proc/version 2>/dev/null; then
    echo "WSL2 detected. Installing wsl.conf..."

    # Backup existing wsl.conf
    if [ -f /etc/wsl.conf ]; then
      mkdir -p ~/.dotfiles_old
      sudo cp -av /etc/wsl.conf ~/.dotfiles_old/wsl.conf
    fi

    sudo cp -v "$(pwd)/wsl.conf" /etc/wsl.conf
    echo "WSL2 configuration installed!"
    echo "Run 'wsl --shutdown' from PowerShell and reopen WSL to apply."
  fi
}

if [ "$1" = "minimal" ]
then
  install_dotfiles
else
  install_devtools
  install_dotfiles
fi
