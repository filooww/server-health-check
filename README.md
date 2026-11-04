# server-health-check

## Example output

Report header: host name and time of the run.

```
========================================
       SERVER DIAGNOSTICS REPORT
Host: lab | Wed Nov  4 03:57:04 EET 2026
========================================
```

System: host name and how long the server has been running.

```
=== System ===
Hostname : lab
Uptime   : up 2 days, 11 hours, 40 minutes
```

CPU: current usage.

```
=== CPU ===
CPU usage: 3%
```

Memory: used / total and memory available to applications.

```
=== MEMORY ===
Used: 541Mi / 943Mi, available: 401Mi
```

Disk: usage of the root partition. The warning fires when usage crosses the limit.

```
=== DISK ===
Used: 3.7G / 3.9G (98%), free: 113M
WARNING: Disk usage 98% (limit 80%)
```

Top 5 processes by CPU.

```
=== Top 5 processes by CPU consumption ===
    PID %CPU COMMAND
  73375  0.5 kubelet
   9878  0.2 containerd
  10829  0.0 containerd-shim
    584  0.0 multipathd
      1  0.0 systemd
```

Top 5 processes by memory.

```
=== Top 5 processes by memory consumption ===
    PID %MEM COMMAND
  71766  9.8 fwupd
  73375  8.8 kubelet
   9878  4.5 containerd
   1190  2.8 unattended-upgr
   1100  2.7 networkd-dispat
```

Server IP address.

```
=== Server IP address ===
IP address            : 192.168.252.6
```

Network: interface status, gateway, DNS, active connections and an external availability check.

```
=== NETWORK ===
Interface             : enp0s1 -> UP
Gateway 192.168.252.1 : OK
DNS                   : OK
Number of connections : 2
External resource availability check google.com --> OK
```
