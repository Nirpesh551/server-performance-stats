#!/bin/bash

# server-stats.sh - Enhanced server performance monitoring with alerts

# ------------------- CONFIGURABLE THRESHOLDS -------------------
CPU_WARNING=80          # % CPU usage → yellow warning
CPU_CRITICAL=90         # % CPU usage → red critical

DISK_WARNING=15         # % free space left → yellow
DISK_CRITICAL=10        # % free space left → red

MEM_WARNING=80          # % memory used → yellow
MEM_CRITICAL=90         # % memory used → red
# ---------------------------------------------------------------

# Colors (only when outputting to terminal)
if [ -t 1 ]; then
    RED=$(tput setaf 1)
    YELLOW=$(tput setaf 3)
    GREEN=$(tput setaf 2)
    RESET=$(tput sgr0)
else
    RED="" YELLOW="" GREEN="" RESET=""
fi

# Default values for options
OUTPUT_FILE=""
VERBOSE=false

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -o FILE    Output results to specified file"
    echo "  -v         Verbose mode (more details)"
    echo "  -h         Show this help message"
    exit 1
}

while getopts ":o:vh" opt; do
    case $opt in
        o) OUTPUT_FILE="$OPTARG" ;;
        v) VERBOSE=true ;;
        h) usage ;;
        \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
    esac
done

if [ -n "$OUTPUT_FILE" ]; then
    exec > "$OUTPUT_FILE"
    # No colors when redirecting to file
    RED="" YELLOW="" GREEN="" RESET=""
fi

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "${GREEN}Server Performance Statistics - Generated on: $TIMESTAMP${RESET}"
echo "========================================================================="
echo ""

if $VERBOSE; then
    echo "[VERBOSE] Running in detailed mode"
    echo ""
fi

# Status tracking
warnings=0
criticals=0

status_ok()    { echo "${GREEN}OK${RESET}"; }
status_warning() { ((warnings++)); echo "${YELLOW}WARNING${RESET}"; }
status_critical() { ((criticals++)); echo "${RED}CRITICAL${RESET}"; }

# 1. System Information
echo "=== System Information ==="
echo "Hostname: $(hostname)"
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p)"
echo "Load Average: $(cat /proc/loadavg | awk '{print $1", "$2", "$3}')"
echo ""

# 2. CPU Usage + Alert
echo "=== CPU Usage ==="
cpu_idle=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print $1}')
cpu_usage=$(awk "BEGIN {print 100 - $cpu_idle}")
echo -n "Total CPU Usage: $cpu_usage% → "
if (( $(echo "$cpu_usage > $CPU_CRITICAL" | bc -l) )); then status_critical
elif (( $(echo "$cpu_usage > $CPU_WARNING" | bc -l) )); then status_warning
else status_ok; fi
echo ""

# 3. Memory Usage + Alert
echo "=== Memory Usage ==="
mem_total=$(free | awk '/^Mem:/ {print $2}')
mem_used=$(free | awk '/^Mem:/ {print $3}')
mem_used_pct=$(awk "BEGIN {printf \"%.1f\", $mem_used * 100 / $mem_total}")
echo -n "Memory Used: $mem_used_pct% → "
if (( $(echo "$mem_used_pct > $MEM_CRITICAL" | bc -l) )); then status_critical
elif (( $(echo "$mem_used_pct > $MEM_WARNING" | bc -l) )); then status_warning
else status_ok; fi
echo "  (Total: $(free -h | awk '/^Mem:/ {print $2}'))"
echo ""

# 4. Disk Usage + Alert (checks root filesystem for simplicity)
echo "=== Disk Usage (root filesystem) ==="
disk_free_pct=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%')
disk_free_pct_num=${disk_free_pct%\%}
echo -n "Root (/): $disk_free_pct used → "
free_space_pct=$((100 - disk_free_pct_num))
if [ $free_space_pct -le $DISK_CRITICAL ]; then status_critical
elif [ $free_space_pct -le $DISK_WARNING ]; then status_warning
else status_ok; fi
echo "  ($free_space_pct% free)"
echo ""

# 5. Top 5 Processes by CPU
echo "=== Top 5 Processes by CPU ==="
ps -eo pid,ppid,cmd,%cpu --sort=-%cpu | head -n 6
echo ""

# 6. Top 5 Processes by Memory
echo "=== Top 5 Processes by Memory ==="
ps -eo pid,ppid,cmd,%mem --sort=-%mem | head -n 6
echo ""

# Summary
echo "=== Health Summary ==="
if [ $criticals -gt 0 ]; then
    echo "${RED}CRITICAL ISSUES DETECTED ($criticals)${RESET}"
elif [ $warnings -gt 0 ]; then
    echo "${YELLOW}WARNINGS FOUND ($warnings)${RESET}"
else
    echo "${GREEN}All systems OK${RESET}"
fi
echo ""

if $VERBOSE; then
    echo "[VERBOSE] Extra info:"
    echo "  - Thresholds: CPU warn>$CPU_WARNING%, crit>$CPU_CRITICAL%"
    echo "  -           Mem  warn>$MEM_WARNING%, crit>$MEM_CRITICAL%"
    echo "  -           Disk free warn<$DISK_WARNING%, crit<$DISK_CRITICAL%"
fi
