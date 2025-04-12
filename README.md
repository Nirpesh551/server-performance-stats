#  Server Performance Monitoring Script

A Bash script to analyze key Linux server metrics including CPU, memory, disk usage, and process statistics.

![Bash](https://img.shields.io/badge/shell_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)

##  Project URL
**GitHub Repository:**  
https://github.com/Nirpesh551/server-performance-stats

##  Features
- **CPU Usage**: Total utilization percentage
- **Memory Analysis**: Used/Free with percentages
- **Disk Monitoring**: Filesystem usage stats
- **Process Tracking**: Top 5 CPU/Memory consumers
- **System Info**: OS, uptime, load average (stretch goals)

##  Quick Start
```bash
# 1. Download the script
wget https://raw.githubusercontent.com/Nirpesh551/server-performance-stats/main/server-stats.sh

# 2. Make executable
chmod +x server-stats.sh

# 3. Run it
./server-stats.sh
