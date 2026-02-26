# Server Performance Monitoring Script

A professional-grade Bash utility to analyze key Linux server metrics, featuring active monitoring, JSON exporting, and automated webhook alerting.

![Bash](https://img.shields.io/badge/shell_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)

## Project URL
**GitHub Repository:** [https://github.com/Nirpesh551/server-performance-stats](https://github.com/Nirpesh551/server-performance-stats)

## Features
- **Active Alerting**: Send critical threshold alerts directly to Discord or Slack via Webhooks.
- **JSON Export Mode**: Seamlessly integrate output into APIs, databases, or dashboards.
- **Service Health Checks**: Verify essential services (like Nginx, Docker, SSH) are actively running.
- **CPU & Memory Analysis**: Accurate, real-time utilization percentages.
- **Disk Monitoring**: Track root filesystem usage to prevent storage crashes.
- **Color-Coded CLI**: Beautiful, human-readable terminal output.

## Quick Start

```bash
# 1. Download the script
wget [https://raw.githubusercontent.com/Nirpesh551/server-performance-stats/main/server-stats.sh](https://raw.githubusercontent.com/Nirpesh551/server-performance-stats/main/server-stats.sh)

# 2. Make executable
chmod +x server-stats.sh

# 3. Run basic check
./server-stats.sh
