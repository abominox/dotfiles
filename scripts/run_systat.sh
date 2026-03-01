#!/bin/bash

if [[ "$(uname)" == "Darwin" ]]; then
    BIN="./systat_macos"
elif [[ "$(uname)" == "Linux" ]]; then
    BIN="./systat_linux"
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

# Add @reboot crontab entry if not already present
CRON_LINE="@reboot $(pwd)/$(basename "$0")"
(crontab -l 2>/dev/null | grep -F -q "$CRON_LINE") || \
    (crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab -
