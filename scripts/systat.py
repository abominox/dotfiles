#!/usr/bin/python3
"""System Statistics Printout for tmux Statusline"""

from datetime import datetime
import psutil

print(str(psutil.cpu_percent(interval=0.1)) + "/" \
    + str(psutil.virtual_memory()._asdict().get("percent")) \
    + str(datetime.now().strftime(' | %r | %a %b %d, %Y')))
