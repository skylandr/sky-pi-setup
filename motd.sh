#!/bin/bash
clear
GRE='\e[0;32m'
RED='\e[0;31m'
BLK='\e[0;39m'

echo -e ${GRE}"==========================================================================="
echo -e ${RED}"$(figlet -k $(hostname))\n"
echo -e ${GRE}"==========================================================================="
echo -e ${BLK}"Welcome        : Hello $(whoami). You are logged on $(hostname)"
echo "Last Login     : $(lastlog -u $(whoami) | awk 'NR==2 { printf "on %s %s %s %s at %s from %s\n",$4,$6,$5,$9,$7,$3 }')"
echo "Uptime         : $(uptime -p) since $(uptime -s)"
echo "Model          : $(tr -d '\0' < /sys/firmware/devicetree/base/model)"
echo "CPU            : $(lscpu | grep 'Model name' | awk -F':' '{ print $2}' | sed 's/ *//') - $(lscpu | grep 'CPU(s)' | awk -F':' 'NR==1 {print $2 }' | sed 's/ *//') cores @ $(lscpu | grep -i 'cpu max' | awk -F':' '{ print $2 }' | sed 's/ *//' | awk -F'.' '{ print $1}') Mhz)"
echo "CPU Temp       : $(vcgencmd measure_temp | cut -c "6-9") C"
echo "CPU Load       : $(cat /proc/loadavg | awk '{ printf "%s (1min) %s (5min) %s (15min)\n",$1,$2,$3 }')"
echo "RAM            : $(free -m | awk 'NR==2 { printf "Total: %sMB, Used: %sMB, Free: %sMB\n",$2,$3,$4; }')"
echo "ROOT Space     : $(df -h | awk 'NR==2 { printf "Total: %sB, Used: %sB, Free: %sB\n",$2,$3,$4; }')"
echo "NFS Space      : $(df -h | grep '/media/video' | awk '{ printf "Total: %sB, Used: %sB, Free: %sB\n",$2,$3,$4 }')"
echo "WAN IP         : $(wget -q -O - http://icanhazip.com/ | tail)"
echo "Service Status :"
echo " - Docker      : $(systemctl status docker.service | grep Active: | awk '{ print $2,$3 }')"
echo -e ${GRE}"==========================================================================="
echo -e ${BLK}