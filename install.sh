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
  .fonts
  .Xresources
  .Xauthority
)

# Fish shell configuration directory
fish_config_dir="$HOME/.config/fish"

# Packages with identical names across all package managers
common_packages=(tmux vim git curl htop ncdu shellcheck jq fish)

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

install_bun () {
  if ! command -v bun &> /dev/null; then
    curl -fsSL https://bun.sh/install | bash
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
      brew install "${common_packages[@]}" python3 eza coreutils pi-coding-agent
      brew install --cask font-jetbrains-mono-nerd-font
      install_bun
      ;;

    debian)
      sudo apt update && sudo apt install -y \
        "${common_packages[@]}" net-tools python3 python3-pip virtualenv
      # Install a modern Node.js (Pi needs >= 20, Debian bookworm only has 18)
      install_nodejs_debian
      install_bun
      # Install pi coding agent via bun (avoids EACCES with npm on Debian)
      bun install -g @mariozechner/pi-coding-agent
      install_eza_debian
      ;;

    arch)
      sudo pacman -Syu --noconfirm \
        "${common_packages[@]}" net-tools python python-pip python-virtualenv eza nodejs npm
      install_bun
      # Install pi coding agent via bun (avoids potential EACCES with npm)
      bun install -g @mariozechner/pi-coding-agent
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

  # Install Claude Code configuration
  install_claude_config

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
    if [[ "$(basename "$func_file")" == "pi.fish" && "$(detect_platform)" != "macos" ]]; then
      continue
    fi
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

    ln -fnvs "$DOTFILES_DIR/ghostty/config" "$ghostty_dir/config"
  echo "Ghostty configuration installed!"
}

install_claude_config () {
  echo "Setting up Claude Code configuration..."

  mkdir -p "$HOME/.claude"

  if [ -f "$HOME/.claude/settings.json" ] && [ ! -L "$HOME/.claude/settings.json" ]; then
    mkdir -p ~/.dotfiles_old/claude
    cp -av "$HOME/.claude/settings.json" ~/.dotfiles_old/claude/settings.json
  fi

    ln -fnvs "$DOTFILES_DIR/.claude/settings.json" "$HOME/.claude/settings.json"

  # Install ccusage for Claude Code statusline
  if command -v bun &> /dev/null; then
    bun install -g ccusage
  fi

  echo "Claude Code configuration installed!"
}

install_pi_config () {
  echo "Setting up pi configuration..."

  mkdir -p "$HOME/.pi/agent"

  # Backup existing settings if not already symlinked
  if [ -f "$HOME/.pi/agent/settings.json" ] && [ ! -L "$HOME/.pi/agent/settings.json" ]; then
    mkdir -p ~/.dotfiles_old/pi
    cp -av "$HOME/.pi/agent/settings.json" ~/.dotfiles_old/pi/settings.json
  fi

  # Symlink top-level config files (create them in ~/.dotfiles/pi/ to manage)
  for f in settings.json keybindings.json models.json mcp.json; do
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
  # Creates a hard link to node named "pi" so macOS records pbsi_comm = "pi"
  # at the kernel level, fixing tmux showing "node" instead of "pi".
  if [[ "$(detect_platform)" != "macos" ]]; then
    return 0
  fi
  if ! command -v pi &> /dev/null || ! command -v node &> /dev/null; then
    return 0
  fi

  echo "Setting up pi node wrapper for tmux compatibility..."

  local target="$HOME/.local/share/pi/pi"
  local node_bin
  node_bin="$(realpath /opt/homebrew/opt/node/bin/node 2>/dev/null || realpath "$(which node)")"
  local lib_dir="$(dirname "$node_bin")/../lib"

  mkdir -p "$(dirname "$target")"
  ln -f "$node_bin" "$target"

  # Symlink libnode alongside so @rpath resolves correctly
  for lib in "$lib_dir"/libnode*.dylib; do
    [ -f "$lib" ] || continue
    ln -sf "$lib" "$(dirname "$target")"/"$(basename "$lib")"
  done

  # The fish function at ~/.dotfiles/fish/functions/pi.fish is symlinked
  # automatically by install_fish_config above.

  echo "Created pi node wrapper at $target"
}

# Ensure pi (and other global binaries) are on PATH
# On Linux, pi may be installed via npm or bun, each with a different bin dir.
# The script's PATH may not include them depending on how it was invoked.
ensure_pi_on_path () {
  if command -v bun &> /dev/null; then
    local bun_bin
    bun_bin="$(bun pm bin -g 2>/dev/null)"
    if [ -n "$bun_bin" ] && [ -d "$bun_bin" ]; then
      case ":$PATH:" in
        *":$bun_bin:"*) : ;;
        *) export PATH="$bun_bin:$PATH" ;;
      esac
    fi
  fi
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

  # Ensure pi is on PATH (npm global bin not always in script PATH on Linux)
  ensure_pi_on_path

  if ! command -v pi &> /dev/null; then
    echo "  ⚠️  pi not found on PATH — skipping package installs"
    return 0
  fi

  # Pi requires Node.js >= 20 (uses /v regex flag)
  if command -v node &> /dev/null; then
    local node_major
    node_major="$(node --version | cut -d'.' -f1 | tr -d 'v')"
    if [ "$node_major" -lt 20 ]; then
      echo "  ⚠️  pi requires Node.js >= 20 (found v$node_major) — skipping package installs"
      echo "  Run: curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash"
      return 0
    fi
  fi

  # Re-install known packages (tracked via install commands, not code)
  pi install npm:pi-wierd-statusline
  pi install npm:pi-web-access
  pi install npm:pi-btw          # Side conversation overlay (/btw, /btw:new, /btw:tangent, etc.)
  pi install npm:pi-mcp-adapter   # MCP (Model Context Protocol) adapter

  echo "pi packages installed!"
}

install_yazi_config () {
  echo "Setting up yazi configuration..."

  local yazi_dir="$HOME/.config/yazi"
  mkdir -p "$yazi_dir"

  # Backup existing keymap if it's not already a symlink to our dotfiles
  if [ -f "$yazi_dir/keymap.toml" ] && [ ! -L "$yazi_dir/keymap.toml" ]; then
    mkdir -p ~/.dotfiles_old/yazi
    cp -av "$yazi_dir/keymap.toml" ~/.dotfiles_old/yazi/keymap.toml
  fi

  # Symlink each yazi config file from ~/.dotfiles/yazi/
  for f in "$DOTFILES_DIR"/yazi/*.toml; do
    [ -f "$f" ] || continue
    ln -fnvs "$f" "$yazi_dir/$(basename "$f")"
  done

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
