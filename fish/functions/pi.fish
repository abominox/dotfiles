#!/usr/bin/env fish
#
# pi.fish — Fish function override for Pi coding agent
# =========
#
# Why this exists
# ---------------
# Tmux gets pane_current_command from macOS's kernel-level pbsi_comm field
# (via proc_pidinfo(PROC_PIDT_SHORTBSDINFO)). Pi's process.title change
# only updates ps -o comm (via setproctitle()), but macOS retains the
# original binary basename in pbsi_comm — always "node" — so tmux windows
# all show "node" instead of "pi".
#
# The fix: exec a hard link to the node binary named "pi" so the kernel
# records pbsi_comm = "pi" at execve() time, before any code runs.
#
# Platform note
# -------------
# - **macOS**: tmux reads pbsi_comm from proc_pidinfo() — immutable after execve.
#   This function is required to make tmux show "pi".
# - **Linux**: tmux reads /proc/pid/cmdline (argv[0]). Pi's existing
#   process.title = "pi" already updates argv[0], so tmux shows "pi" without
#   any workaround. install.sh skips symlinking this file on non-macOS.
#   See osdep-linux.c vs osdep-darwin.c in the tmux source.
#
# How it works
# ------------
# 1. Maintains a hard link ~/.local/share/pi/pi -> /opt/homebrew/opt/node/bin/node
#    (plus symlinks to libnode dylibs, since @rpath resolves relative to
#    the hard link's location).
# 2. The hard link is self-healing: if node is upgraded (different inode),
#    the function re-creates it and symlinks all matching libnode dylibs on next launch.
# 3. Resolves the actual Pi CLI JS entry point via realpath(1), making it
#    survive brew upgrade pi-coding-agent.
# 4. Replaces the shell with exec so tmux sees the node process directly.
#
# Dependencies
# ------------
# - ~/.local/share/pi/pi           Hard link to node (created automatically)
# - ~/.local/share/pi/libnode.*.dylib  Symlinks for @rpath (created automatically)
# - /opt/homebrew/bin/pi           Homebrew's pi symlink (resolved for CLI path)
# - /opt/homebrew/opt/node/bin/node    Homebrew's node symlink (source of hard link)
# - realpath (macOS built-in /bin/realpath)
#
# See also
# --------
# - ~/.dotfiles/install.sh — install_pi_node_wrapper() creates the initial hard link
# - tmux/osdep-darwin.c — reads pbsi_comm via proc_pidinfo
# - tmux/osdep-linux.c  — reads argv[0] via /proc/pid/cmdline
#

function pi --wraps=pi --description "Launch Pi coding agent (via node hardlink for tmux compat)"
    # Hard link to node named "pi" so macOS records pbsi_comm = "pi" at the
    # kernel level (what tmux reads for pane_current_command).
    set -l pi_node "$HOME/.local/share/pi/pi"
    set -l node_bin (realpath /opt/homebrew/opt/node/bin/node)
    set -l lib_dir (dirname "$node_bin")/../lib

    # Create/refresh the hard link and lib symlinks on node upgrades
    if not test -f "$pi_node"
        or test (stat -f '%i' "$pi_node") != (stat -f '%i' "$node_bin")
        mkdir -p (dirname "$pi_node")
        ln -f "$node_bin" "$pi_node"
        # libnode dylibs are found via @rpath; the hard link changes the
        # loader path, so we need libnode alongside the hard link.
        # The .dylib itself uses absolute paths for its deps — no further links needed.
        # Remove stale dylib symlinks (e.g. after node upgrade)
        for stale in (dirname "$pi_node")/libnode*.dylib
            if not test -f (readlink "$stale")
                rm -f "$stale"
            end
        end
        for lib in $lib_dir/libnode*.dylib
            ln -sf "$lib" (dirname "$pi_node")/(basename "$lib")
        end
    end

    # Resolve Pi CLI entry point (version-independent).
    # Symlink chain: /opt/homebrew/bin/pi -> Cellar/bin/pi (shell script)
    #                -> libexec/bin/pi -> dist/cli.js
    # We skip the Cellar/bin/pi shell script and resolve through libexec/bin/pi
    # so the node hardlink gets the actual JS entry point.
    set -l pi_cellar (dirname (realpath /opt/homebrew/bin/pi))
    set -l pi_cli (realpath "$pi_cellar/../libexec/bin/pi")

    # Replace the shell — tmux sees pbsi_comm = "pi"
    exec "$pi_node" "$pi_cli" $argv
end
