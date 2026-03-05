#!/bin/bash

AUTH_WARNING=5
AUTH_CRITICAL=20
ALLOWED_PORTS=("22" "80" "443")
CPU_WARNING=80
CPU_CRITICAL=90
DISK_WARNING=15
DISK_CRITICAL=10
MEM_WARNING=80
MEM_CRITICAL=90

SERVICES=("sshd" "docker" "nginx")

if [ -t 1 ]; then
    RED=$(tput setaf 1)
    YELLOW=$(tput setaf 3)
    GREEN=$(tput setaf 2)
    RESET=$(tput sgr0)
else
    RED="" YELLOW="" GREEN="" RESET=""
fi

OUTPUT_FILE=""
VERBOSE=false
JSON_MODE=false
WEBHOOK_URL=""

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -o FILE    Output results to specified file"
    echo "  -j         Output strictly in JSON format"
    echo "  -w URL     Webhook URL (Discord/Slack) to send critical alerts"
    echo "  -v         Verbose mode (more details)"
    echo "  -h         Show this help message"
    exit 1
}

while getopts ":o:w:jvh" opt; do
    case $opt in
        o) OUTPUT_FILE="$OPTARG" ;;
        w) WEBHOOK_URL="$OPTARG" ;;
        j) JSON_MODE=true ;;
        v) VERBOSE=true ;;
        h) usage ;;
        \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
    esac
done

if [ -n "$OUTPUT_FILE" ]; then
    exec > "$OUTPUT_FILE"
    RED="" YELLOW="" GREEN="" RESET=""
fi

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
warnings=0
criticals=0
ALERT_MESSAGES=""

status_ok()    { echo "${GREEN}OK${RESET}"; }
status_warning() { ((warnings++)); echo "${YELLOW}WARNING${RESET}"; }
status_critical() { ((criticals++)); echo "${RED}CRITICAL${RESET}"; }


HOSTNAME=$(hostname)
OS=$(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
UPTIME=$(uptime -p)
LOAD=$(cat /proc/loadavg | awk '{print $1", "$2", "$3}')

# --- CPU Calculation via Kernel (/proc/stat) ---
read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
prev_idle=$((idle + iowait))
prev_total=$((user + nice + system + idle + iowait + irq + softirq + steal))

sleep 0.5 

read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
idle_time=$((idle + iowait))
total=$((user + nice + system + idle + iowait + irq + softirq + steal))

cpu_usage=$(awk "BEGIN {printf \"%.1f\", 100 * (1 - (($idle_time - $prev_idle) / ($total - $prev_total)))}")

cpu_status="OK"
if awk "BEGIN {exit !($cpu_usage > $CPU_CRITICAL)}"; then
    cpu_status="CRITICAL"
    ((criticals++))
    ALERT_MESSAGES="$ALERT_MESSAGES\n- CPU Usage is Critical: $cpu_usage%"
elif awk "BEGIN {exit !($cpu_usage > $CPU_WARNING)}"; then
    cpu_status="WARNING"
    ((warnings++))
fi

# --- Memory Calculation via Kernel (/proc/meminfo) ---
mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
mem_avail=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
mem_used=$((mem_total - mem_avail))
mem_used_pct=$(awk "BEGIN {printf \"%.1f\", $mem_used * 100 / $mem_total}")

mem_status="OK"
if awk "BEGIN {exit !($mem_used_pct > $MEM_CRITICAL)}"; then
    mem_status="CRITICAL"
    ((criticals++))
    ALERT_MESSAGES="$ALERT_MESSAGES\n- Memory Usage is Critical: $mem_used_pct%"
elif awk "BEGIN {exit !($mem_used_pct > $MEM_WARNING)}"; then
    mem_status="WARNING"
    ((warnings++))
fi

disk_free_pct=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%')
free_space_pct=$((100 - disk_free_pct))
disk_status="OK"
if [ $free_space_pct -le $DISK_CRITICAL ]; then 
    disk_status="CRITICAL"
    ((criticals++))
    ALERT_MESSAGES="$ALERT_MESSAGES\n- Root Disk Space Critical: Only $free_space_pct% free"
elif [ $free_space_pct -le $DISK_WARNING ]; then 
    disk_status="WARNING"
    ((warnings++))
fi

# --- Security Auditing: Failed SSH Logins ---
failed_logins=$(journalctl -u sshd --since "1 hour ago" --no-pager 2>/dev/null | grep -i "Failed password" | wc -l)
auth_status="OK"

if [ "$failed_logins" -gt "$AUTH_CRITICAL" ]; then
    auth_status="CRITICAL"
    ((criticals++))
    ALERT_MESSAGES="$ALERT_MESSAGES\n- CRITICAL SECURITY: $failed_logins failed SSH logins in the last hour!"
elif [ "$failed_logins" -gt "$AUTH_WARNING" ]; then
    auth_status="WARNING"
    ((warnings++))
fi

# --- Security Auditing: Unauthorized Open Ports ---
unauthorized_ports=""
listening_ports=$(ss -tuln | awk 'NR>1 {print $5}' | awk -F':' '{print $NF}' | sort -u)

for port in $listening_ports; do
    is_allowed=false
    for allowed in "${ALLOWED_PORTS[@]}"; do
        if [ "$port" == "$allowed" ]; then
            is_allowed=true
            break
        fi
    done
    if [ "$is_allowed" = false ]; then
        unauthorized_ports="$unauthorized_ports $port"
    fi
done

port_status="OK"
if [ -n "$unauthorized_ports" ]; then
    port_status="WARNING"
    ((warnings++))
    ALERT_MESSAGES="$ALERT_MESSAGES\n- SECURITY WARNING: Unauthorized open ports detected:$unauthorized_ports"
fi

if $JSON_MODE; then
    cat <<EOF
{
  "timestamp": "$TIMESTAMP",
  "system": {
    "hostname": "$HOSTNAME",
    "os": "$OS",
    "uptime": "$UPTIME",
    "load_average": "$LOAD"
  },
  "metrics": {
    "cpu_usage_pct": $cpu_usage,
    "cpu_status": "$cpu_status",
    "mem_usage_pct": $mem_used_pct,
    "mem_status": "$mem_status",
    "disk_free_pct": $free_space_pct,
    "disk_status": "$disk_status"
  },
  "security": {
    "failed_ssh_logins_1h": $failed_logins,
    "auth_status": "$auth_status",
    "unauthorized_ports": "$unauthorized_ports",
    "port_status": "$port_status"
  },
  "health": {
    "warnings": $warnings,
    "criticals": $criticals
  }
}
EOF
else
    echo "${GREEN}Server Performance Statistics - Generated on: $TIMESTAMP${RESET}"
    echo "========================================================================="
    
    echo -e "\n=== System Information ==="
    echo "Hostname: $HOSTNAME"
    echo "OS: $OS"
    echo "Uptime: $UPTIME"
    echo "Load Average: $LOAD"

    echo -e "\n=== Resources ==="
    echo -n "CPU Usage: $cpu_usage% → "
    [ "$cpu_status" == "CRITICAL" ] && echo "${RED}CRITICAL${RESET}" || ([ "$cpu_status" == "WARNING" ] && echo "${YELLOW}WARNING${RESET}" || echo "${GREEN}OK${RESET}")

    echo -n "Memory Used: $mem_used_pct% → "
    [ "$mem_status" == "CRITICAL" ] && echo "${RED}CRITICAL${RESET}" || ([ "$mem_status" == "WARNING" ] && echo "${YELLOW}WARNING${RESET}" || echo "${GREEN}OK${RESET}")

    echo -n "Disk Free Space (/): $free_space_pct% → "
    [ "$disk_status" == "CRITICAL" ] && echo "${RED}CRITICAL${RESET}" || ([ "$disk_status" == "WARNING" ] && echo "${YELLOW}WARNING${RESET}" || echo "${GREEN}OK${RESET}")


    echo -e "\n=== Security Audit ==="
    echo -n "Failed SSH Logins (Last 1h): $failed_logins → "
    [ "$auth_status" == "CRITICAL" ] && echo "${RED}CRITICAL${RESET}" || ([ "$auth_status" == "WARNING" ] && echo "${YELLOW}WARNING${RESET}" || echo "${GREEN}OK${RESET}")

    echo -n "Unauthorized Listening Ports: "
    if [ -n "$unauthorized_ports" ]; then
        echo "${YELLOW}$unauthorized_ports${RESET}"
    else
        echo "${GREEN}None${RESET}"
    fi

    echo -e "\n=== Service Health ==="
    for service in "${SERVICES[@]}"; do
        if systemctl is-active --quiet "$service"; then
            echo "$service: ${GREEN}Running${RESET}"
        else
            echo "$service: ${RED}Stopped${RESET}"
            ((criticals++))
            ALERT_MESSAGES="$ALERT_MESSAGES\n- Service Stopped: $service"
        fi
    done

    echo -e "\n=== Health Summary ==="
    if [ $criticals -gt 0 ]; then
        echo "${RED}CRITICAL ISSUES DETECTED ($criticals)${RESET}"
    elif [ $warnings -gt 0 ]; then
        echo "${YELLOW}WARNINGS FOUND ($warnings)${RESET}"
    else
        echo "${GREEN}All systems OK${RESET}"
    fi
fi

if [ -n "$WEBHOOK_URL" ] && [ $criticals -gt 0 ]; then
    PAYLOAD=$(cat <<EOF
{"content": "**SERVER ALERT: $HOSTNAME** \n$ALERT_MESSAGES"}
EOF
)
    curl -s -H "Content-Type: application/json" -X POST -d "$PAYLOAD" "$WEBHOOK_URL" > /dev/null
    
    if [ "$JSON_MODE" = false ] && [ "$VERBOSE" = true ]; then
        echo -e "\n[VERBOSE] Alert dispatched to Webhook."
    fi
fi
