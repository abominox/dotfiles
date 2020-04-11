#!/usr/bin/env python3
"""systat"""

import psutil

print(str(psutil.cpu_percent(interval=1.0)) + "/" + str(psutil.virtual_memory()._asdict().get("percent")))