#!/bin/sh
# Launch system statistics program

if [ "$PLATFORM" = "Darwin" ]; then
	cp -a systat_darwin /tmp/systat
fi

# If systat binary is not in /tmp, copy it there
if [ ! -f "/tmp/systat" ]; then
    cp -a systat /tmp/systat
fi

# Do not launch again if already running
if pgrep -x "systat" > /dev/null; then
    exit 0
else
    /tmp/systat &
fi
