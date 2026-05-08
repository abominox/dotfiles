#!/bin/bash
# This script installs my dotfiles + some extras into any *nix system.
# Requires Bash. Supports macOS (brew), Debian/Ubuntu (apt), and Arch Linux (pacman).

# Directory where the script lives (resolved once, immune to caller's CWD)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

dotfiles=(
  .vim
  .vimrc
  .tmux.conf
  .tmux
)

# Fish shell configuration directory
fish_config_dir="$HOME/.config/fish"

# Packages with identical names across all package managers
common_packages=(tmux vim git curl htop ncdu shellcheck jq fish bat)

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

ensure_homebrew () {
  if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
}

install_nodejs_debian () {
  if command -v node &> /dev/null; then
    local major
    major="$(node --version | cut -d'.' -f1 | tr -d 'v')"
    [ "$major" -ge 20 ] && return 0
  fi
  echo "Installing Node.js 22.x via NodeSource (Pi requires Node >= 20)..."
  if ! curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - 2>/dev/null; then
    echo "  ⚠️  Could not install Node.js 22 automatically (sudo may need a TTY)."
    echo "  Run this manually: curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash"
    return 1
  fi
  sudo apt install -y nodejs
}

# Backup a regular file to ~/.dotfiles_old/<label>/ if it exists and isn't a symlink
backup_if_real () {
  local src="$1"
  local label="$2"
  if [ -f "$src" ] && [ ! -L "$src" ]; then
    mkdir -p ~/.dotfiles_old/"$label"
    cp -av "$src" ~/.dotfiles_old/"$label"/"$(basename "$src")"
  fi
}

install_eza_debian () {
  if ! command -v eza &> /dev/null; then
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    sudo apt update && sudo apt install -y eza
  fi
}

install_devtools () {
  local platform
  platform=$(detect_platform)

  echo "Detected platform: $platform"

  case "$platform" in
    macos)
      ensure_homebrew
      brew install "${common_packages[@]}" python3 eza coreutils git-delta glow chafa imagemagick
      # Unlink brew's pi if present (avoids EEXIST conflict with npm global install)
      # Pin brew's pi so upgrade doesn't re-link and clobber the npm global binary
      brew unlink pi-coding-agent 2>/dev/null || true
      brew pin pi-coding-agent 2>/dev/null || true
      npm install -g --force @earendil-works/pi-coding-agent
      brew install --cask font-jetbrains-mono-nerd-font
      pip3 install readability-lxml html2text
      ;;

    debian)
      sudo apt update && sudo apt install -y \
        "${common_packages[@]}" net-tools python3 python3-pip virtualenv
      # Install a modern Node.js (Pi needs >= 20, Debian bookworm only has 18)
      install_nodejs_debian
      npm install -g @earendil-works/pi-coding-agent
      pip3 install readability-lxml html2text
      install_eza_debian
      # git-delta and glow not in Debian bookworm repos — install manually:
      if ! command -v delta &> /dev/null; then
        echo "  git-delta: install via cargo (cargo install git-delta) or from github.com/dandavison/delta"
        echo "    (available behind backports for trixie, see packages.debian.org/git-delta)"
      fi
      if ! command -v glow &> /dev/null; then
        echo "  glow: install from github.com/charmbracelet/glow/releases (grab the .deb)"
      fi
      ;;

    arch)
      sudo pacman -Syu --noconfirm \
        "${common_packages[@]}" net-tools python python-pip python-virtualenv eza nodejs npm git-delta glow
      npm install -g @earendil-works/pi-coding-agent
      pip3 install readability-lxml html2text
      ;;

    *)
      echo "Unknown platform. Please install packages manually."
      return 1
      ;;
  esac

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
    ln -fnvs "$DOTFILES_DIR"/"$dotfile" ~/"$dotfile"
  done

  # Install Fish configuration
  install_fish_config

  # Install Ghostty configuration (macOS only)
  install_ghostty_config

  # Install pi configuration
  install_pi_config

  # Install pi node wrapper (macOS only — tmux compat, pbsi_comm="pi")
  install_pi_node_wrapper

  # Install pi packages
  install_pi_packages

  # Install yazi configuration
  install_yazi_config

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
  ln -fnvs "$DOTFILES_DIR/fish/config.fish" "$fish_config_dir/config.fish"

  # Symlink conf.d files
  for conf_file in "$DOTFILES_DIR"/fish/conf.d/*.fish; do
    [ -f "$conf_file" ] || continue
    ln -fnvs "$conf_file" "$fish_config_dir/conf.d/$(basename "$conf_file")"
  done

  # Symlink functions
  for func_file in "$DOTFILES_DIR"/fish/functions/*.fish; do
    [ -f "$func_file" ] || continue
    # pi.fish is a macOS-specific tmux workaround — skip on Linux
    if [[ "$(basename "$func_file")" == "pi.fish" && "$PLATFORM" != "macos" ]]; then
      continue
    fi
    ln -fnvs "$func_file" "$fish_config_dir/functions/$(basename "$func_file")"
  done

  echo "Fish configuration installed!"
  echo "To set Fish as default shell, run: chsh -s \$(which fish)"
}

install_ghostty_config () {
  if [[ "$PLATFORM" != "macos" ]]; then
    return 0
  fi

  local ghostty_dir="$HOME/Library/Application Support/com.mitchellh.ghostty"
  echo "Setting up Ghostty configuration..."

  mkdir -p "$ghostty_dir"
  backup_if_real "$ghostty_dir/config" ghostty
  ln -fnvs "$DOTFILES_DIR/ghostty/config" "$ghostty_dir/config"
  echo "Ghostty configuration installed!"
}



install_pi_config () {
  echo "Setting up pi configuration..."

  mkdir -p "$HOME/.pi/agent"

  # Backup existing settings if not already symlinked
  backup_if_real "$HOME/.pi/agent/settings.json" pi

  # Symlink top-level config files (create them in ~/.dotfiles/pi/ to manage)
  for f in settings.json keybindings.json models.json mcp.json AGENTS.md; do
    if [ -f "$DOTFILES_DIR/pi/$f" ]; then
      ln -fnvs "$DOTFILES_DIR/pi/$f" "$HOME/.pi/agent/$f"
    fi
  done

  # Symlink plugin-related directories (pi packages, skills, prompts, themes, extensions)
  # These persist your installed "plugins" / customizations
  for dir in skills prompts themes extensions git; do
    if [ -d "$DOTFILES_DIR/pi/$dir" ]; then
      mkdir -p "$HOME/.pi/agent/$dir"
      for item in "$DOTFILES_DIR/pi/$dir"/*; do
        [ -e "$item" ] || continue
        ln -fnvs "$item" "$HOME/.pi/agent/$dir/$(basename "$item")"
      done
    fi
  done

  echo "pi configuration installed! (run 'pi' to complete setup/login)"
}

install_pi_node_wrapper () {
  if [[ "$PLATFORM" != "macos" ]]; then
    return 0
  fi
  if ! command -v pi &> /dev/null || ! command -v node &> /dev/null; then
    return 0
  fi

  echo "Setting up pi node wrapper for tmux compatibility..."

  local target node_bin lib_dir
  target="$HOME/.local/share/pi/pi"
  node_bin="$(realpath "$(which node)")"
  lib_dir="$(dirname "$node_bin")/../lib"

  mkdir -p "$(dirname "$target")"
  ln -f "$node_bin" "$target"

  for lib in "$lib_dir"/libnode*.dylib; do
    [ -f "$lib" ] || continue
    ln -sf "$lib" "$(dirname "$target")"/"$(basename "$lib")"
  done

  echo "Created pi node wrapper at $target"
}

# Ensure pi is on PATH
ensure_pi_on_path () {
  if command -v npm &> /dev/null; then
    local npm_bin
    npm_bin="$(npm root -g 2>/dev/null)/../bin"
    if [ -n "$npm_bin" ] && [ -d "$npm_bin" ]; then
      case ":$PATH:" in
        *":$npm_bin:"*) : ;;
        *) export PATH="$npm_bin:$PATH" ;;
      esac
    fi
  fi
}

install_pi_packages () {
  echo "Installing pi packages..."

  ensure_pi_on_path

  if ! command -v pi &> /dev/null; then
    echo "  ⚠️  pi not found on PATH — skipping package installs"
    return 0
  fi

  # Pi requires Node.js >= 20
  if command -v node &> /dev/null; then
    local node_major
    node_major="$(node --version | cut -d'.' -f1 | tr -d 'v')"
    if [ "$node_major" -lt 20 ]; then
      echo "  ⚠️  pi requires Node.js >= 20 (found v$node_major) — skipping package installs"
      return 0
    fi
  fi

  # pi install uses npm internally — ensure writable prefix on Linux
  if [ -d /usr/lib/node_modules ] && [ ! -w /usr/lib/node_modules ]; then
    local npm_prefix="$HOME/.npm-global"
    mkdir -p "$npm_prefix"
    export npm_config_prefix="$npm_prefix"
    export PATH="$npm_prefix/bin:$PATH"
  fi

  # Read packages from settings.json (single source of truth)
  local pi_settings="$DOTFILES_DIR/pi/settings.json"
  if [ ! -f "$pi_settings" ]; then
    echo "  ⚠️  No pi/settings.json found — nothing to install"
    return 0
  fi

  # Parse each entry: strings are package sources, objects have a "source" field
  while IFS= read -r pkg; do
    [ -z "$pkg" ] && continue
    echo "  Installing package: $pkg..."
    pi install "$pkg"
  done < <(jq -r '.packages[] | if type == "object" then .source else . end' "$pi_settings" 2>/dev/null || grep -o '"[a-z][a-z]*:[^"]*"' "$pi_settings" | tr -d '"')

  echo "pi packages installed!"
}

install_yazi_config () {
  echo "Setting up yazi configuration..."

  local yazi_dir="$HOME/.config/yazi"
  mkdir -p "$yazi_dir"

  # Backup existing keymap if it's not already a symlink to our dotfiles
  backup_if_real "$yazi_dir/keymap.toml" yazi

  # Symlink each yazi config file from ~/.dotfiles/yazi/
  for f in "$DOTFILES_DIR"/yazi/*.toml; do
    [ -f "$f" ] || continue
    ln -fnvs "$f" "$yazi_dir/$(basename "$f")"
  done

  # Install yazi plugins (zoom.yazi, etc.)
  if command -v ya &> /dev/null; then
    ya pkg install 2>/dev/null || true
  fi

  echo "yazi configuration installed!"
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

    sudo cp -v "$DOTFILES_DIR/wsl.conf" /etc/wsl.conf
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
