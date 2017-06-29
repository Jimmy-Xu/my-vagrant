#!/bin/bash -e

IFADDR="172.222.0.1/24"

DOCKER0=`ifconfig docker0 2>/dev/null | grep "inet " | awk '{print $2}'`

if [ "$DOCKER0" == "" ];then
  ip link add docker0 type bridge
  ip addr add "$IFADDR" dev docker0
  ip link set docker0 up
  iptables -t nat -A POSTROUTING -s "$IFADDR" ! -d "$IFADDR" -j MASQUERADE

  rm /mnt/vdb/var/lib/docker -rf 2>/dev/null

  echo 1 > /proc/sys/net/ipv4/ip_forward
fi
