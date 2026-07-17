#!/bin/bash
# Push /tmp/statusline into zjstatus via pipe (keeps last value across tab creates).
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATUSLINE_SH="$SCRIPT_DIR/statusline.sh"
PIDFILE="/tmp/zjstatus-pipe.pid"
INTERVAL="${ZJSTATUS_PIPE_INTERVAL:-1}"
LAST=""

if [[ -f "$PIDFILE" ]]; then
    OLD_PID=$(cat "$PIDFILE" 2>/dev/null || true)
    if [[ -n "${OLD_PID:-}" ]] && kill -0 "$OLD_PID" 2>/dev/null; then
        kill "$OLD_PID" 2>/dev/null || true
        sleep 0.1
    fi
    rm -f "$PIDFILE"
fi

echo $$ > "$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT

while true; do
    if [[ -x "$STATUSLINE_SH" ]] && command -v zellij >/dev/null 2>&1; then
        content=$("$STATUSLINE_SH" 2>/dev/null | tr -d '\n\r' || true)
        if [[ -n "${content:-}" ]]; then
            # Always push so brand-new tabs get a value within ~1s.
            # Skip EXITED (resurrectable) sessions — piping them is slow/useless.
            while IFS= read -r session; do
                [[ -z "$session" ]] && continue
                zellij --session "$session" pipe \
                    "zjstatus::pipe::pipe_systat::${content}" 2>/dev/null || true
            done < <(zellij list-sessions -n 2>/dev/null | grep -v EXITED | awk '{print $1}' || true)

        fi
    fi
    sleep "$INTERVAL"
done
