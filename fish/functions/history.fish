#!/usr/bin/env fish
# Override default history command to show timestamps like my custom BASH output

function history -d "Show command history with timestamps"
    # If arguments are provided, pass them to the builtin history command
    if test (count $argv) -gt 0
        builtin history $argv
        return
    end

    # Use Python to parse and format Fish history
    python3 -c '
import re
from datetime import datetime

hist_file = "'$HOME'/.local/share/fish/fish_history"
count = 1

try:
    with open(hist_file, "r") as f:
        content = f.read()

    # Parse entries (- cmd: followed by when:)
    entries = re.findall(r"- cmd: (.*?)\n  when: (\d+)", content, re.DOTALL)

    # Show last 1000
    for cmd, timestamp in entries[-1000:]:
        # Format timestamp
        dt = datetime.fromtimestamp(int(timestamp))
        formatted = dt.strftime("%m/%d/%y %I:%M:%S %p")
        # Clean up command (remove extra spaces/newlines)
        cmd = cmd.strip().replace("\n", " ")
        print(f"{count:5d}  {formatted} --> {cmd}")
        count += 1
except FileNotFoundError:
    print("No history file found")
'
end
