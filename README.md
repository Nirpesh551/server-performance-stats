# DevSecOps Server & Security Monitor

A professional-grade, zero-dependency Bash utility built to analyze key Linux server metrics, dynamically profile resource hogs, and audit system defense posture. 

![Bash](https://img.shields.io/badge/shell_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![Security](https://img.shields.io/badge/DevSecOps-Ready-blue?style=for-the-badge&logo=shield&logoColor=white)

## Multi-Cloud Architecture
This monitor is designed to secure and observe distributed, multi-cloud topologies. The intended deployment architecture routes monitoring across:
* **Control Plane**
* **Worker Nodes**
## Top-Tier Features

* **The "Blame Engine" (Process Profiling):** Doesn't just tell you CPU/Memory is high; dynamically captures and reports the exact PIDs and processes causing the spike.
* **Active Security Auditing:** Parses system journals to detect SSH brute-force attempts and scans for unauthorized listening TCP ports.
* **Defense Posture Validation:** Verifies that a firewall (UFW, firewalld, or iptables) is active and detects orphaned "Zombie" processes degrading performance.
* **Zero-Dependency Native Metrics:** Bypasses brittle tools like `top` and `bc`. Calculates floating-point metrics natively reading from `/proc/stat` and `/proc/meminfo` using `awk`.
* **JSON Export & Webhook Integration:** Seamlessly routes structured critical alerts to Discord/Slack webhooks or API endpoints.

## Quick Start

```bash
# 1. Download the script
wget [https://raw.githubusercontent.com/Nirpesh551/server-performance-stats/main/server-stats.sh](https://raw.githubusercontent.com/Nirpesh551/server-performance-stats/main/server-stats.sh)

# 2. Make executable
chmod +x server-stats.sh

# 3. Run full DevSecOps audit
./server-stats.sh

# 4. Output strictly in JSON
./server-stats.sh -j
