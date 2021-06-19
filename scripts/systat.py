#!/usr/bin/python3
"""System Statistics Printout for tmux Statusline"""

import psutil
from datetime import datetime

print(str(psutil.cpu_percent(interval=0.0)) + "/" \
    + str(psutil.virtual_memory()._asdict().get("percent")) \
    + ' | ' \
    + str(datetime.now().strftime('%r | %a %b %d, %Y')))
