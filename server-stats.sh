#!/bin/bash

# server-stats.sh - Enhanced server performance monitoring script

# Default values for options
OUTPUT_FILE=""
VERBOSE=false

# Help/usage message
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -o FILE    Output results to specified file (instead of terminal)"
    echo "  -v         Verbose mode (shows more details)"
    echo "  -h         Show this help message and exit"
    exit 1
}

# Parse command line options
while getopts ":o:vh" opt; do
    case $opt in
        o) OUTPUT_FILE="$OPTARG" ;;
        v) VERBOSE=true ;;
        h) usage ;;
        \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
    esac
done

# If output file is specified, redirect all output to it
if [ -n "$OUTPUT_FILE" ]; then
    exec > "$OUTPUT_FILE"
fi

# Timestamp for the report
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Header
echo "Server Performance Statistics - Generated on: $TIMESTAMP"
echo "===================================================="
echo ""

# Verbose mode info
if $VERBOSE; then
    echo "[VERBOSE] Running in detailed mode"
    echo ""
fi

# 1. System Information
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
free -h | awk '/^Mem:/ {printf "Total: %s\nUsed:  %s (%.1f%%)\nFree:  %s (%.1f%%)\n", $2, $3, $3/$2*100, $4, $4/$2*100}'
echo ""

# 4. Disk Usage
echo "=== Disk Usage ==="
df -h | awk '$1 ~ /^\/dev\// {print $1 ": " $3 " used (" $5 "), " $4 " free"}'
echo ""

# 5. Top 5 Processes by CPU Usage
echo "=== Top 5 Processes by CPU Usage ==="
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6
echo ""

# 6. Top 5 Processes by Memory Usage
echo "=== Top 5 Processes by Memory Usage ==="
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6
echo ""

# 7. Failed Login Attempts (Last 24h)
echo "=== Failed Login Attempts (Last 24h) ==="
journalctl --since "24 hours ago" -t sshd | grep "Failed password" | wc -l | awk '{print $1 " failed login attempts"}'
echo ""

# Optional: verbose extra info example
if $VERBOSE; then
    echo ""
    echo "[VERBOSE] Current date/time detail:"
    date
    echo "[VERBOSE] Current working directory:"
    pwd
fi
