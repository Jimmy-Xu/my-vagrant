#!/bin/bash

username="vagrant"
password="vagrant"

if [ $# -eq 0 ];then
    echo "Usage: sudo ./check_ip.sh <host_id>/<host_name>"
    echo "host list:"
    virsh list | grep "ceph-ansible" | awk '{printf "%-3s%s\n",$1,$2}'
    exit 1
fi

expect -c "
    set timeout 3 
    spawn virsh console $1 
    expect {
	\"Escape character\" {send \"\r\r\" ; exp_continue} 
	\"login:\" {send \"$username\r\"; exp_continue}
	\"Password:\" {send \"$password\r\";} 
	} 
    send_user \"\renter $1\r\"
    expect \"*\$\"
    send \"(ip addr| grep eth0 -A1 | grep inet) && echo has ip || sudo dhclient eth0\r\" 
    expect \"*\$\"
    send \"exit\r\"
    expect \"login:\"
    send \"\"
    expect eof
"
