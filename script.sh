#!/bin/bash
set -uo pipefail
# Limits

DISK_LIMIT=80
MEMORY_LIMIT=90
CPU_LIMIT=85

# percentage of CPU, Memory and Disk usage to trigger an alert
DISK_PCT=$(df / --output=pcent / | tail -1 | tr -dc '0-9')
MEMORY_PCT=$(free | awk '/Mem:/ {printf "%d", ($2-$7)/$2*100}')
CPU_PCT=$(vmstat 1 2 | tail -1 | awk '{print 100 - $15}')

# Vars
HOST=$(hostname)
DATE=$(date)
UP=$(uptime -p)
CPU=$(vmstat 1 2 | tail -1 | awk '{print 100 - $15 "%"}')
MEMORY=$(free -h | awk '/Mem:/ {print "Used: "$3" / "$2", available: "$7""}')
DISK=$(df -h / | awk 'NR==2 {print "Used: "$3" / "$2" ("$5"), free: "$4""}')
CPU_TOP=$(ps -eo pid,%cpu,comm --sort=-%cpu | head -6)
MEM_TOP=$(ps -eo pid,%mem,comm --sort=-%mem | head -6)
IP=$(hostname -I | awk '{print $1}')
IFACE=$(ip route | awk '/default/ {print $5; exit}')
NET_STAT1=$(ip -br addr show "$IFACE" | awk '{print $1 " -> " $2}')
GW=$(ip route | awk '/default/ {print $3; exit}')
CONN_CNT=$(ss -tanH state established | wc -l)
REPORT="report_$(date +%F_%H-%M-%S).txt"

#Print WARNINGS if thresholds are exceeded
threshold() {
  local name="$1" value="$2" limit="$3"
  if (( value >= limit)); then
    printf "WARNING: %s usage %s%% (limit %s%%)\n" "$name" "$value" "$limit"
  fi
}

# Save all output to a report file and show it on screen
exec > >(tee "$REPORT") 2>&1

# Function for headers
section() {
    echo
    echo "=== $1 ==="
}


echo ========================================
echo "       SERVER DIAGNOSTICS REPORT"
echo "Host: $HOST | $DATE"
echo ========================================

# Section about hostname and uptime
section "System"
echo "Hostname : $HOST"
echo "Uptime   : $UP"

# Section about CPU usage
section "CPU"
echo "CPU usage: $CPU"
threshold "CPU" "$CPU_PCT" "$CPU_LIMIT"

# Section about memory usage
section "MEMORY"
echo "$MEMORY"
threshold "Memory" "$MEMORY_PCT" "$MEMORY_LIMIT"
# Section about disk usage
section "DISK"
echo "$DISK"
threshold "Disk" "$DISK_PCT" "$DISK_LIMIT"

# In this section we can see top 5 processes by CPU utilization
section "Top 5 processes by CPU consumption"
echo "$CPU_TOP"

# In this section we can see top 5 processes by mem utilization
section "Top 5 processes by memory consumption"
echo "$MEM_TOP"

# Section IP address
section "Server IP address"
echo "IP address            : $IP"

# In this section we can see network checks
section "NETWORK"

echo "Interface             : $NET_STAT1"

if ping -c 1 -W 2 "$GW" > /dev/null 2>&1; then
    echo "Gateway $GW : OK"
else
    echo "Gateway $GW : FAIL"
fi

if getent hosts google.com > /dev/null; then
    echo "DNS                   : OK"
else
    echo "DNS                   : FAIL"
fi

echo "Number of connections : $CONN_CNT"

if ping -c 1 -W 2 google.com > /dev/null 2>&1; then
    echo "External resource availability check google.com --> OK"
else
    echo "External resource availability check google.com --> FAIL"
fi
