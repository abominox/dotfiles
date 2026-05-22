#!/bin/bash
# This script installs my dotfiles + some extras into any *nix system.
# Requires Bash. Supports macOS (brew), Debian/Ubuntu (apt), and Arch Linux (pacman).

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

# Directory where the script lives (resolved once, immune to caller's CWD)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM="$(detect_platform)"

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

# ── Shared helpers ──────────────────────────────────────────────────────────

# Install pi coding agent (handles bun cleanup + npm prefix on Linux)
_install_pi () {
  # Remove stale bun-installed pi (shadows npm version on PATH)
  rm -f "$HOME/.bun/bin/pi" 2>/dev/null || true

  # On Linux, set user-writable npm prefix (system prefix is root-owned)
  if [[ "$PLATFORM" != "macos" ]] && ! npm prefix -g 2>/dev/null | grep -q "$HOME/.npm-global"; then
    mkdir -p "$HOME/.npm-global"
    npm config set prefix "$HOME/.npm-global" 2>/dev/null || true
    export npm_config_prefix="$HOME/.npm-global"
    export PATH="$HOME/.npm-global/bin:$PATH"
  fi

  npm install -g @earendil-works/pi-coding-agent
}

# Install python tools via uv (not pip3 — avoids externally-managed-environment issues)
_install_pip_tools () {
  if ! command -v uv &> /dev/null; then
    echo "  Installing uv (Python package manager)..."
    if [[ "$PLATFORM" == "macos" ]]; then
      brew install uv
    else
      curl -fsSL https://astral.sh/uv/install.sh | sh
    fi
  fi
  uv pip install --system readability-lxml html2text 2>/dev/null || \
    pip3 install --break-system-packages readability-lxml html2text 2>/dev/null || \
    pip3 install readability-lxml html2text
}

# Install rtk (Rust Token Killer)
_install_rtk () {
  if command -v rtk &> /dev/null; then
    return 0
  fi
  echo "  Installing rtk (Rust Token Killer)..."
  if [[ "$PLATFORM" == "macos" ]]; then
    brew install rtk
  else
    curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
  fi
}

# Check if a pi package source is already installed (so we can skip reinstall)
_pi_package_installed () {
  local pkg="$1"
  case "$pkg" in
    npm:*)
      local name="${pkg#npm:}"
      [ -d "$(npm root -g)/$name" ] 2>/dev/null
      return $?
      ;;
    git:*)
      local path="${pkg#git:}"
      [ -d "$HOME/.pi/agent/git/$path" ] 2>/dev/null
      return $?
      ;;
    *)
      return 1 ;;
  esac
}

# ── Devtools ────────────────────────────────────────────────────────────────

install_devtools () {
  local platform
  platform=$(detect_platform)

  echo "Detected platform: $platform"

  case "$platform" in
    macos)
      ensure_homebrew
      brew install "${common_packages[@]}" python3 eza coreutils git-delta glow chafa imagemagick
      brew unlink pi-coding-agent 2>/dev/null || true
      brew pin pi-coding-agent 2>/dev/null || true
      _install_pi
      # Ensure pi is actually runnable (npm may install to a different prefix,
      # or the shell has a stale hash cache)
      hash -r 2>/dev/null || true
      if ! command -v pi &> /dev/null || [ ! -x "$(command -v pi)" ]; then
        local npm_pi_bin="$(npm root -g 2>/dev/null)/../../bin/pi"
        if [ -x "$npm_pi_bin" ]; then
          mkdir -p /opt/homebrew/bin 2>/dev/null
          ln -sf "$npm_pi_bin" /opt/homebrew/bin/pi 2>/dev/null || true
        fi
      fi
      brew install --cask font-jetbrains-mono-nerd-font
      _install_pip_tools
      _install_rtk
      ;;

    debian)
      sudo apt update && sudo apt install -y \
        "${common_packages[@]}" net-tools python3 python3-pip virtualenv
      install_nodejs_debian
      _install_pi
      _install_pip_tools
      install_eza_debian
      _install_rtk
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
      _install_pi
      _install_pip_tools
      _install_rtk
      ;;

    *)
      echo "Unknown platform. Please install packages manually."
      return 1
      ;;
  esac
}

# ── Dotfiles ────────────────────────────────────────────────────────────────

install_dotfiles () {
  for dotfile in "${dotfiles[@]}"
  do
    if [ -f "$dotfile" ]; then
      mkdir -p ~/.dotfiles_old
      cp -av ~/"$dotfile" ~/.dotfiles_old/"$dotfile"
    fi
    ln -fnvs "$DOTFILES_DIR"/"$dotfile" ~/"$dotfile"
  done

  install_fish_config
  install_ghostty_config
  install_pi_config
  install_pi_node_wrapper
  install_pi_packages
  install_yazi_config
  install_wsl_config
}

install_fish_config () {
  echo "Setting up Fish shell configuration..."

  mkdir -p "$fish_config_dir"
  mkdir -p "$fish_config_dir/conf.d"
  mkdir -p "$fish_config_dir/functions"
  mkdir -p "$fish_config_dir/completions"

  if [ -f "$fish_config_dir/config.fish" ]; then
    mkdir -p ~/.dotfiles_old/fish
    cp -av "$fish_config_dir"/* ~/.dotfiles_old/fish/ 2>/dev/null || true
  fi

  ln -fnvs "$DOTFILES_DIR/fish/config.fish" "$fish_config_dir/config.fish"

  for conf_file in "$DOTFILES_DIR"/fish/conf.d/*.fish; do
    [ -f "$conf_file" ] || continue
    ln -fnvs "$conf_file" "$fish_config_dir/conf.d/$(basename "$conf_file")"
  done

  for func_file in "$DOTFILES_DIR"/fish/functions/*.fish; do
    [ -f "$func_file" ] || continue
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
  backup_if_real "$HOME/.pi/agent/settings.json" pi

  for f in settings.json keybindings.json models.json mcp.json AGENTS.md; do
    if [ -f "$DOTFILES_DIR/pi/$f" ]; then
      ln -fnvs "$DOTFILES_DIR/pi/$f" "$HOME/.pi/agent/$f"
    fi
  done

  for dir in skills prompts themes extensions git; do
    if [ -d "$DOTFILES_DIR/pi/$dir" ]; then
      mkdir -p "$HOME/.pi/agent/$dir"
      for item in "$DOTFILES_DIR/pi/$dir"/*; do
        [ -e "$item" ] || continue
        ln -fnvs "$item" "$HOME/.pi/agent/$dir/$(basename "$item")"
      done
    fi
  done

  # Restore extension configs from dotfiles
  for ext_conf in "$DOTFILES_DIR/pi/extensions"/*/config.json; do
    [ -f "$ext_conf" ] || continue
    local ext_name
    ext_name="$(basename "$(dirname "$ext_conf")")"
    mkdir -p "$HOME/.pi/agent/extensions/$ext_name"
    cp -v "$ext_conf" "$HOME/.pi/agent/extensions/$ext_name/config.json"
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
    npm_bin="$(npm root -g 2>/dev/null)/../../bin"
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

  if command -v node &> /dev/null; then
    local node_major
    node_major="$(node --version | cut -d'.' -f1 | tr -d 'v')"
    if [ "$node_major" -lt 20 ]; then
      echo "  ⚠️  pi requires Node.js >= 20 (found v$node_major) — skipping package installs"
      return 0
    fi
  fi

  local pi_settings="$DOTFILES_DIR/pi/settings.json"
  if [ ! -f "$pi_settings" ]; then
    echo "  ⚠️  No pi/settings.json found — nothing to install"
    return 0
  fi

  while IFS= read -r pkg; do
    [ -z "$pkg" ] && continue

    # Skip if already installed
    if _pi_package_installed "$pkg"; then
      echo "  ✔️  $pkg already installed — skipping"
      continue
    fi

    echo "  Installing package: $pkg..."
    pi install "$pkg" || echo "  ⚠️  Failed to install $pkg"
  done < <(jq -r '.packages[] | if type == "object" then .source else . end' "$pi_settings" 2>/dev/null || grep -o '"[a-z][a-z]*:[^"]*"' "$pi_settings" | tr -d '"')

  echo "pi packages installed!"
}

install_yazi_config () {
  echo "Setting up yazi configuration..."

  local yazi_dir="$HOME/.config/yazi"
  mkdir -p "$yazi_dir"

  backup_if_real "$yazi_dir/keymap.toml" yazi

  for f in "$DOTFILES_DIR"/yazi/*.toml; do
    [ -f "$f" ] || continue
    ln -fnvs "$f" "$yazi_dir/$(basename "$f")"
  done

  if command -v ya &> /dev/null; then
    ya pkg install 2>/dev/null || true
  fi

  echo "yazi configuration installed!"
}

install_wsl_config () {
  if grep -qi microsoft /proc/version 2>/dev/null; then
    echo "WSL2 detected. Installing wsl.conf..."

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