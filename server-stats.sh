#!/bin/bash

# server-stats.sh - A script to analyze basic server performance stats
# Timestamp for report generation
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "Server Performance Statistics - Generated on: $TIMESTAMP"
echo "===================================================="
echo ""

# 1. System Information (stretch goal)
echo "=== System Information ==="
echo "Hostname: $(hostname)"
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p)"
echo "Load Average: $(cat /proc/loadavg | awk '{print $1", "$2", "$3}')"
echo "Logged-in Users: $(who | wc -l)"
echo ""

# 2. Total CPU Usage
echo "=== CPU Usage ==="
cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')
echo "Total CPU Usage: $cpu_usage"
echo ""

# 3. Memory Usage
echo "=== Memory Usage ==="
free -h | awk '/^Mem:/ {print "Total: " $2, "Used: " $3 " (" $3/$2 * 100 "%)", "Free: " $4 " (" $4/$2 * 100 "%)"}'
echo ""

# 4. Disk Usage
echo "=== Disk Usage ==="
df -h | awk '/^\/dev\// {print $1 ": " $3 " used (" $5 "), " $4 " free"}'
echo ""

# 5. Top 5 Processes by CPU Usage
echo "=== Top 5 Processes by CPU Usage ==="
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6
echo ""

# 6. Top 5 Processes by Memory Usage
echo "=== Top 5 Processes by Memory Usage ==="
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6
echo ""

# 7. Failed Login Attempts (stretch goal)
echo "=== Failed Login Attempts (Last 24h) ==="
journalctl --since "24 hours ago" -t sshd | grep "Failed password" | wc -l | awk '{print $1 " failed login attempts"}'
echo ""
