#!/bin/bash
VIRBR0=`ifconfig virbr0 2>/dev/null | grep "inet " | awk '{print $2}'`
if [ "$VIRBR0" != "" -a "$VIRBR0" != "192.168.222.1" ];then
  virsh net-destroy default
  systemctl stop libvirtd
else
  echo skip process virbr0
fi
