# Start ceph cluster with vagrant + libvirt + qemu(kvm) + centos7
## start all vms

```shell
$ ./util.sh run
  ...
  PLAY RECAP *********************************************************************
  mon0                       : ok=72   changed=15   unreachable=0    failed=0   
  mon1                       : ok=69   changed=14   unreachable=0    failed=0   
  mon2                       : ok=69   changed=14   unreachable=0    failed=0   
  osd0                       : ok=43   changed=11   unreachable=0    failed=0   
  osd1                       : ok=42   changed=11   unreachable=0    failed=0   
  osd2                       : ok=42   changed=11   unreachable=0    failed=0
```

## list all vms

```
$ ./util.sh list
  Current machine states:
  mon0                      running (libvirt)
  mon1                      running (libvirt)
  mon2                      running (libvirt)
  osd0                      running (libvirt)
  osd1                      running (libvirt)
  osd2                      running (libvirt)
```

## connect to vm
### connect to osd

```shell
$ cd ceph-ansible
$ vagrant ssh osd0
  Last login: Fri Jan 29 13:05:28 2016 from 192.168.121.1
  [vagrant@ceph-osd0 ~]$ sudo yum install net-tools
  [vagrant@ceph-osd0 ~]$ ip addr | grep "inet.*eth."
    inet 192.168.121.206/24 brd 192.168.121.255 scope global dynamic eth0
    inet 192.168.42.100/24 brd 192.168.42.255 scope global eth1

$ sudo netstat -tnopl
  Active Internet connections (only servers)
  Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name     Timer
  tcp        0      0 192.168.42.100:6800     0.0.0.0:*               LISTEN      14474/ceph-osd       off (0.00/0/0)
  tcp        0      0 192.168.42.100:6801     0.0.0.0:*               LISTEN      14474/ceph-osd       off (0.00/0/0)
  tcp        0      0 192.168.42.100:6802     0.0.0.0:*               LISTEN      14474/ceph-osd       off (0.00/0/0)
  tcp        0      0 192.168.42.100:6803     0.0.0.0:*               LISTEN      14474/ceph-osd       off (0.00/0/0)
  tcp        0      0 192.168.42.100:6804     0.0.0.0:*               LISTEN      15147/ceph-osd       off (0.00/0/0)
  tcp        0      0 192.168.42.100:6805     0.0.0.0:*               LISTEN      15147/ceph-osd       off (0.00/0/0)
  tcp        0      0 192.168.42.100:6806     0.0.0.0:*               LISTEN      15147/ceph-osd       off (0.00/0/0)
  tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      923/sshd             off (0.00/0/0)
  tcp        0      0 192.168.42.100:6807     0.0.0.0:*               LISTEN      15147/ceph-osd       off (0.00/0/0)
  tcp        0      0 127.0.0.1:25            0.0.0.0:*               LISTEN      1178/master          off (0.00/0/0)
  tcp6       0      0 :::22                   :::*                    LISTEN      923/sshd             off (0.00/0/0)
  tcp6       0      0 ::1:25                  :::*                    LISTEN      1178/master          off (0.00/0/0)
```

### connect to mon

```
$ cd ceph-ansible
$ vagrant ssh mon0
[vagrant@ceph-mon0 ~]$ sudo yum install net-tools
$ sudo netstat -tnopl
  Active Internet connections (only servers)
  Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name     Timer
  tcp        0      0 192.168.42.10:6789      0.0.0.0:*               LISTEN      13459/ceph-mon       off (0.00/0/0)
  tcp        0      0 192.168.42.10:5000      0.0.0.0:*               LISTEN      14979/python         off (0.00/0/0)
  tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      919/sshd             off (0.00/0/0)
  tcp        0      0 127.0.0.1:25            0.0.0.0:*               LISTEN      1144/master          off (0.00/0/0)
  tcp6       0      0 :::22                   :::*                    LISTEN      919/sshd             off (0.00/0/0)
  tcp6       0      0 ::1:25                  :::*                    LISTEN      1144/master          off (0.00/0/0)
```

## delete all vms

```shell
$ ./util.sh destroy
```
