#!/bin/bash

if [[ "$(uname)" == "Darwin" ]]; then
    BIN="./systat_macos"
elif [[ "$(uname)" == "Linux" ]]; then
    BIN="./systat_linux"
else
    echo "Unsupported OS: $(uname)"
    exit 1
fi

# Run the binary and write output to /tmp/statusline
"$BIN" > /tmp/statusline &

# Add @reboot crontab entry if not already present
CRON_LINE="@reboot $(pwd)/$(basename "$0")"
(crontab -l 2>/dev/null | grep -F -q "$CRON_LINE") || \
    (crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab -
