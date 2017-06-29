#!/bin/bash -e

DOCKER0=`ifconfig docker0 2>/dev/null | grep "inet " | awk '{print $2}'`

if [ "$DOCKER0" != "" -a "$DOCKER0" != "172.222.0.1" ];then
  iptables -t nat -F
  ifconfig docker0 down
  brctl delbr docker0

  systemctl stop docker
else
  echo skip process docker0
fi
