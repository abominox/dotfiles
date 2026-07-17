#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")"

if [[ "$(uname)" == "Darwin" ]]; then
    BIN="$SCRIPT_DIR/systat_macos"
elif [[ "$(uname)" == "Linux" ]]; then
    if [[ "$(uname -m)" == "aarch64" ]]; then
        BIN="$SCRIPT_DIR/systat_linux_arm64"
    else
        BIN="$SCRIPT_DIR/systat_linux"
    fi
else
    echo "Unsupported OS: $(uname)"
    exit 1
fi

PIDFILE="/tmp/systat.pid"

# Kill any existing instance
if [[ -f "$PIDFILE" ]]; then
    OLD_PID=$(cat "$PIDFILE")
    if kill -0 "$OLD_PID" 2>/dev/null && ps -p "$OLD_PID" -o comm= | grep -qF "systat"; then
        kill "$OLD_PID"
    fi
    rm -f "$PIDFILE"
fi

# Run the binary and write output to /tmp/statusline
"$BIN" &
echo $! > "$PIDFILE"

# Push statusline into zjstatus via pipe (avoids empty bar on new tabs)
PIPE_SCRIPT="$(cd "$SCRIPT_DIR/../zellij/scripts" 2>/dev/null && pwd)/zjstatus-pipe.sh"
if [[ ! -x "$PIPE_SCRIPT" ]]; then
    PIPE_SCRIPT="$HOME/.dotfiles/zellij/scripts/zjstatus-pipe.sh"
fi
if [[ -x "$PIPE_SCRIPT" ]]; then
    # Restart pipe pusher
    if [[ -f /tmp/zjstatus-pipe.pid ]]; then
        OLD_PIPE=$(cat /tmp/zjstatus-pipe.pid 2>/dev/null || true)
        if [[ -n "${OLD_PIPE:-}" ]] && kill -0 "$OLD_PIPE" 2>/dev/null; then
            kill "$OLD_PIPE" 2>/dev/null || true
        fi
        rm -f /tmp/zjstatus-pipe.pid
    fi
    nohup "$PIPE_SCRIPT" >/dev/null 2>&1 &
fi

# Ensure exactly one @reboot crontab entry for this script, removing any stale ones
CRON_LINE="@reboot $SCRIPT_PATH"
crontab -l 2>/dev/null | grep -v -F "run_systat.sh" | (cat; echo "$CRON_LINE") | crontab -
