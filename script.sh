#!/bin/bash
set -uo pipefail
# Limits

DISK_LIMIT=80
MEMORY_LIMIT=90
CPU_LIMIT=85

# Disk usage percentage of the root partition
get_disk_usage() {
    df / --output=pcent | tail -1 | tr -dc '0-9'
}

# Get CPU usage details from /proc/stat
get_cpu_usage() {
    local t1 i1 t2 i2
    read -r t1 i1 < <(awk '/^cpu /{print $2+$3+$4+$5+$6+$7+$8+$9, $5+$6}' /proc/stat)
    sleep 1
    read -r t2 i2 < <(awk '/^cpu /{print $2+$3+$4+$5+$6+$7+$8+$9, $5+$6}' /proc/stat)
    echo $((100 * ((t2 - t1) - (i2 -i1)) / (t2 - t1)))
}

# Get memory usage details from /proc/meminfo
get_memory_usage() {
    awk '/^MemTotal:/    {total=$2}
         /^MemAvailable:/ {available=$2}
         END {printf "Used: %dMi / %dMi, available: %dMi", (total-available)/1024, total/1024, available/1024}' /proc/meminfo
}

#Memory usage percentage
get_memory_percentage() {
    awk '/^MemTotal:/    {total=$2}
         /^MemAvailable:/ {available=$2}
         END {printf "%.0f", (total - available) / total * 100}' /proc/meminfo
}

# Top 5 processes by CPU usage
top_by_cpu() {
    read -r up _ < /proc/uptime
    echo "    PID %CPU COMMAND"
    awk -v up="$up" '{ t = up - $22/100; if (t > 0) printf "%7s %4.1f %s\n", $1, ($14+$15)/t, $2 }' \
        /proc/[0-9]*/stat 2>/dev/null | sort -k2 -rn | head -5
}

# Top 5 processes by memory usage
top_by_mem() {
    local total
    total=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
    echo "    PID %MEM COMMAND"
    awk '/^Name:/ {name=$2} /^Pid:/ {pid=$2} /^VmRSS:/ {print pid, $2, name}' \
        /proc/[0-9]*/status 2>/dev/null | sort -k2 -rn | head -5 |
        awk -v t="$total" '{printf "%7s %4.1f %s\n", $1, $2*100/t, $3}'
}

#Print WARNINGS if thresholds are exceeded
threshold() {
  local name="$1" value="$2" limit="$3"
  if (( value >= limit)); then
    printf "WARNING: %s usage %s%% (limit %s%%)\n" "$name" "$value" "$limit"
  fi
}

# Function for headers
section() {
    echo
    echo "=== $1 ==="
}

print_header() {
    echo "========================================"
    echo "       SERVER DIAGNOSTICS REPORT"
    echo "Host: $HOST | $DATE"
    echo "========================================"
}

# Section about hostname and uptime
print_system() {
  section "System"
  echo "Hostname : $HOST"
  echo "Uptime   : $UP"
}

# Section about CPU usage
print_cpu() {
  section "CPU"
  echo "CPU usage: $CPU"
  threshold "CPU" "$CPU_PCT" "$CPU_LIMIT"
}

# Section about memory usage
print_memory() {
  section "MEMORY"
  echo "$MEMORY"
  threshold "Memory" "$MEMORY_PCT" "$MEMORY_LIMIT"
}

# Section about disk usage
print_disk() {
  section "DISK"
  echo "$DISK"
  threshold "Disk" "$DISK_PCT" "$DISK_LIMIT"
}

# In this section we can see top 5 processes by CPU utilization
print_top_cpu() {
  section "Top 5 processes by CPU consumption"
  echo "$CPU_TOP"
}

# In this section we can see top 5 processes by mem utilization
print_top_mem() {
  section "Top 5 processes by memory consumption"
  echo "$MEM_TOP"
}

# Section IP address
print_ip() {
  section "Server IP address"
  echo "IP address            : $IP"
}

# In this section we can see network checks
print_network() {
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
}

# percentage of CPU, Memory and Disk usage to trigger an alert
DISK_PCT=$(get_disk_usage)
MEMORY_PCT=$(get_memory_percentage)
CPU_PCT=$(get_cpu_usage)

# Vars
HOST=$(hostname)
DATE=$(date)
UP=$(uptime -p)
CPU="${CPU_PCT}%"
MEMORY=$(get_memory_usage)
DISK=$(df -h / | awk 'NR==2 {print "Used: "$3" / "$2" ("$5"), free: "$4}')
CPU_TOP=$(top_by_cpu)
MEM_TOP=$(top_by_mem)
IP=$(hostname -I | awk '{print $1}')
IFACE=$(ip route | awk '/default/ {print $5; exit}')
NET_STAT1=$(ip -br addr show "$IFACE" | awk '{print $1 " -> " $2}')
GW=$(ip route | awk '/default/ {print $3; exit}')
CONN_CNT=$(ss -tanH state established | wc -l)
REPORT="report_$(date +%F_%H-%M-%S).txt"

main() {
  # Save all output to a report file and show it on screen
  exec > >(tee "$REPORT") 2>&1
  print_header
  print_system
  print_cpu
  print_memory
  print_disk
  print_top_cpu
  print_top_mem
  print_ip
  print_network
}

main
