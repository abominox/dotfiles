#!/bin/sh
# Strip tmux-style color codes from systat output for zjstatus.
# Keep this script fast and dependency-light (invoked every 1s by zjstatus).
if [ -r /tmp/statusline ]; then
    /usr/bin/sed 's/#\[[^]]*\]//g' /tmp/statusline 2>/dev/null
fi
