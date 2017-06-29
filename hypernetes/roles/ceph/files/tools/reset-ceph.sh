#!/bin/bash

docker ps -a | grep ceph-demo 2>/dev/null
if [ $? -eq 0 ];then
  docker rm -fv ceph-demo
  echo "docker container ceph-demo deleted"
else
  echo "docker container ceph-demo isn't exist"
fi

rm -rf /mnt/vdc/var/log/ceph /mnt/vdc/var/lib/ceph /etc/ceph 2>/dev/null
