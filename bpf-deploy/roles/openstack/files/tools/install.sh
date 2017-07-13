#!/bin/bash

echo "------------------------------------"
env
echo "------------------------------------"

(rpm -qa | grep mariadb-server) && yum remove -y mariadb-server || echo mariadb-server not installed
packstack --answer-file=$1 && touch /root/deps/packstack.ok
