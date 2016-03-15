# Start ceph cluster with vagrant + libvirt + qemu(kvm) + centos7(guest os)
## Manage cluster
### start all vms

```shell
//usage
sudo ./util_centos.sh
  usage: ./util_centos.sh <command>
  <command>:
    run
    quickrun
    halt
    list
    check_ip
    destroy

//start ceph cluster
$ sudo ./util_centos.sh run       //ensure runtime environment, install vagrant,ansible,libvirt...
or
$ sudo ./util_centos.sh quickrun  //skip ensure runtime environment
  ...
  PLAY RECAP *********************************************************************
  mon0                       : ok=73   changed=17   unreachable=0    failed=0   
  osd0                       : ok=43   changed=11   unreachable=0    failed=0   
  osd1                       : ok=42   changed=11   unreachable=0    failed=0   
  osd2                       : ok=42   changed=11   unreachable=0    failed=0   
  rgw0                       : ok=33   changed=12   unreachable=0    failed=0

//to start an existed env
$ cd ceph-ansible
$ sudo vagrant up
  Bringing machine 'client0' up with 'libvirt' provider...
  Bringing machine 'rgw0' up with 'libvirt' provider...
  Bringing machine 'mon0' up with 'libvirt' provider...
  Bringing machine 'osd0' up with 'libvirt' provider...
  Bringing machine 'osd1' up with 'libvirt' provider...
  Bringing machine 'osd2' up with 'libvirt' provider...
  ...
$ sudo vagrant status
  Current machine states:
  client0                   running (libvirt)
  rgw0                      running (libvirt)
  mon0                      running (libvirt)
  osd0                      running (libvirt)
  osd1                      running (libvirt)
  osd2                      running (libvirt)
  ...

// ensure eth0 has ip
$ sudo ./util_centos.sh check_ip
```

### list all vms

```
$ sudo ./util_centos.sh list
  Current machine states:
  client0                   running (libvirt)
  rgw0                      running (libvirt)
  mon0                      running (libvirt)
  osd0                      running (libvirt)
  osd1                      running (libvirt)
  osd2                      running (libvirt)
```

### connect to vm
#### connect to osd

```shell
$ cd ceph-ansible
$ sudo vagrant ssh osd0
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

#### connect to mon

```shell
$ cd ceph-ansible
$ sudo vagrant ssh mon0
[vagrant@ceph-mon0 ~]$ sudo yum install -y net-tools
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

#### connect to client0
> Copy the ceph configuration file and ceph keyring to each server you plan to mount ceph block devices onto

```shell
//enter mon0
$ mkdir -p ~/ceph_conf
$ cd ceph-ansible
$ sudo vagrant ssh mon0
  [vagrant@ceph-mon0 ~]$ sudo scp /etc/ceph/ceph.client.admin.keyring /etc/ceph/ceph.conf xjimmy@192.168.1.137:~/ceph_conf/

//change mod of ceph.conf on host
$ chmod 604 ~/ceph_conf/ceph.conf

//enter client0
$ sudo vagrant ssh client0
  [vagrant@ceph-mon0 ~]$ sudo yum install -y ceph-common
  [vagrant@ceph-mon0 ~]$ sudo scp xjimmy@192.168.1.137:~/ceph_conf/* /etc/ceph
  [vagrant@ceph-mon0 ~]$ sudo ceph -s
    cluster ed8f9c62-441e-42f7-b9f7-f12cc9389e67
     health HEALTH_OK
     monmap e1: 1 mons at {ceph-mon0=192.168.42.10:6789/0}
            election epoch 1, quorum 0 ceph-mon0
     mdsmap e2: 0/0/1 up
     osdmap e17: 6 osds: 6 up, 6 in
            flags sortbitwise
      pgmap v31: 320 pgs, 3 pools, 0 bytes data, 0 objects
            206 MB used, 66711 MB / 66917 MB avail
                 320 active+clean
```

### delete all vms

```shell
$ sudo ./util_centos.sh destroy
```

## Usage
> Run the folloing command in client0

### mange pool

```shell
//create pool
$ ceph osd pool create test_pool 1024

//list pool
$ rados lspools | grep test_pool
or
$ ceph osd pool ls | grep test_pool

//rename pool
$ ceph osd pool rename test_pool test_pool2

//obtain quota of pool
$ ceph osd pool get-quota test_pool2

//obtain stats of pool
$ ceph osd pool stats test_pool2

//get pool parameter
$ ceph osd pool get test_pool2 all

//delete pool
$ ceph osd pool delete test_pool2 test_pool2 --yes-i-really-really-mean-it
```

### manage image

```
//create pool
$ ceph osd pool create test_pool 1024

//create image(256MB)
$ rbd create test_pool/test_image --size 256

//list image
$ rbd ls test_pool
$ rbd list --long test_pool

//obtaint image info
$ rbd info test_pool/test_image

//rename image
$ rbd mv test_pool/test_image test_pool/test_image2
$ rbd rename test_pool/test_image2 test_pool/test_image

//export image to file
$ rbd export test_pool/test_image ./test_image.bak

//import image from file
$ rbd import ./test_image.bak test_pool/test_image2
$ rbd list test_pool

//map image to local device
$ rbd map test_pool/test_image
$ rbd showmapped
$ mkfs.ext4 /dev/rbd0
$ mkdir -p /mnt/test_image
$ mount /dev/rbd0 /mnt/test_image
$ df -hT

//umount image
$ umount /mnt/test_image/

//unmap rbd device
$ rbd unmap /dev/rbd0

//delete image
$ rbd rm test_pool/test_image2

//delete pool
$ ceph osd pool delete test_pool test_pool --yes-i-really-really-mean-it
```

### mange snapshot

```
//create pool
$ ceph osd pool create test_pool 1024

//create image
$ rbd create test_pool/test_image --size 256

//map image to local device
$ rbd map test_pool/test_image
$ rbd showmapped
$ mkfs.ext4 /dev/rbd0
$ mkdir -p /mnt/test_image
$ mount /dev/rbd0 /mnt/test_image

//create snapshot
$ echo 1 > /mnt/test_image/test.txt && \
  umount /mnt/test_image && \
  rbd snap create test_pool/test_image@test_snap1 && \
  mount /dev/rbd0 /mnt/test_image
$ echo 2 > /mnt/test_image/test.txt && \
  umount /mnt/test_image && \
  rbd snap create test_pool/test_image@test_snap2 && \
  mount /dev/rbd0 /mnt/test_image

//list snapshots of a image
$ rbd snap ls test_pool/test_image

//rollback snapshot -> image(original)
$ umount /mnt/test_image/ && \
  rbd snap rollback test_pool/test_image@test_snap1 && \
  mount /dev/rbd0 /mnt/test_image/ && \
  cat /mnt/test_image/test.txt
$ umount /mnt/test_image/ && \
  rbd snap rollback test_pool/test_image@test_snap2 && \
  mount /dev/rbd0 /mnt/test_image/ && \
  cat /mnt/test_image/test.txt


//clone snapshot -> image(new), require protect first
$ rbd snap protect test_pool/test_image@test_snap1 &&\
  rbd clone test_pool/test_image@test_snap1 test_pool/test_image_clone1
$ rbd snap protect test_pool/test_image@test_snap2 &&\
  rbd clone test_pool/test_image@test_snap2 test_pool/test_image_clone2

//list all image
$ rbd ls test_pool --long

//list all clone of a snapshot
$ rbd children test_pool/test_image@test_snap1
$ rbd children test_pool/test_image@test_snap2


//map new image to local device
$ rbd map test_pool/test_image_clone1 && \
  rbd map test_pool/test_image_clone2
$ rbd showmapped
$ mkfs.ext4 /dev/rbd1 && \
  mkfs.ext4 /dev/rbd2
$ mkdir -p /mnt/test_image_clone1 /mnt/test_image_clone2
$ mount /dev/rbd1 /mnt/test_image_clone1 && \
  mount /dev/rbd2 /mnt/test_image_clone2

//unmount all rbd device
$ df -h | grep "\/dev\/rbd" | awk '{print $1}' | xargs -I dev_name umount dev_name
//unmap all rbd device
$ rbd showmapped | grep "\/dev" | awk '{print $NF}' | xargs -I dev_name rbd unmap dev_name

//delete children image
$ rbd rm test_pool/test_image_clone1 &&\
  rbd rm test_pool/test_image_clone2

//delete single snapshot
$ rbd snap unprotect test_pool/test_image@test_snap1 &&\
  rbd snap rm test_pool/test_image@test_snap1
$ rbd snap unprotect test_pool/test_image@test_snap2 &&\
  rbd snap rm test_pool/test_image@test_snap2

//delete all snapshots of a image
$ rbd snap purge test_pool/test_image

//delete image
$ rbd rm test_pool/test_image

//delete pool
$ ceph osd pool delete test_pool test_pool --yes-i-really-really-mean-it
```

## FAQ
### FAQ 1: failed to bind the UNIX domain socket
Error message:

```
$ rados lspools
2016-01-31 03:08:46.458195 7f7d51a9c7c0 -1 asok(0x7f7d530a53a0) AdminSocketConfigO: failed to bind the UNIX domain socket to '/var/run/ceph/rbd-clients/ceph-client. file or directory
```

Solution:

```
// create ceph user
$ sudo useradd -d /home/ceph -m ceph -s /bin/bash
$ sudo passwd ceph
  <Enter password>
$ echo "ceph ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ceph
$ sudo chmod 0440 /etc/sudoers.d/ceph

// set owner of /var/run/ceph
$ sudo mkdir -p /var/run/ceph/rbd-clients/
$ sudo chown ceph:ceph /var/run/ceph -R
```

### FAQ 2: ceph -s clint0 can not connect to mon0
Error message:

```
$ sudo ceph -s
  2016-01-31 01:52:28.746206 7f3ad479a700  0 -- :/1019692 >> 192.168.42.10:6789/0 pipe(0x7f3ad0025050 sd=3 :0 s=1 pgs=0 cs=0 l=1 c=0x7f3ad00252e0).fault
```

Solution:

```
//eth1 can not get ip
$ dhclient eth1
```

### FAQ 3: some tasks failed

Error

```
$ sudo ./util_centos.sh run
  ...
  PLAY RECAP *********************************************************************
  mon0                       : ok=78   changed=5    unreachable=0    failed=1
  osd0                       : ok=48   changed=0    unreachable=0    failed=0
  osd1                       : ok=47   changed=0    unreachable=0    failed=0
  osd2                       : ok=47   changed=0    unreachable=0    failed=0
  rgw0                       : ok=35   changed=1    unreachable=0    failed=1
```

Solution:

```
//try one more time
$ sudo ./util_centos.sh run
or
$ cd ceph-ansible
$ sudo vagrant up
```

### FAQ 4: vagrant up failed with libvirt

Error

```
$ sudo vagrant up --no-provision --provider=libvirt
...
Error while connecting to libvirt: Error making a connection to libvirt URI qemu:///system
```

Solution:

```

```

### FAQ 5: "Bad argument setup" error when run `sudo /sbin/rcvboxdrv setup`

Error

```
$ VBoxManage --version
  WARNING: The vboxdrv kernel module is not loaded. Either there is no module
         available for the current kernel (2.6.38-ARCH) or it failed to
         load. Please recompile the kernel module and install it by

           sudo /sbin/rcvboxdrv setup

         You will not be able to start VMs until this problem is fixed.
$ sudo /sbin/rcvboxdrv setup
  Bad argument setup
```

Solution:

```
$ sudo mv /sbin/rcvboxdrv /sbin/rcvboxdrv.bak
$ sudo ln -s /usr/lib/virtualbox/vboxdrv.sh /sbin/rcvboxdrv
$ sudo /sbin/rcvboxdrv setup
  Stopping VirtualBox kernel modules                         [  OK  ]
  Recompiling VirtualBox kernel modules                      [  OK  ]
  Starting VirtualBox kernel modules                         [  OK  ]
```

### FAQ 6: ansible issue

Error

```
$ sudo vagrant up
  ...
  An exception occurred during task execution. To see the full traceback, use -vvv. The error was: TypeError: set_fs_attributes_if_different() takes exactly 3 arguments (4 given)
  fatal: [mon0 -> localhost]: FAILED! => {"changed": false, "failed": true, "parsed": false}
  ...
```

Solution

```
//updating the submodules the issue was solved.
$ cd ansible && git co -f v2.0.0.2-1 -b v2.0.0.2-1 && git submodule update && make rpm && sudo rpm -Uvh ./rpm-build/ansible-*.noarch.rpm
```

### FAQ 7: "vagrant ssh" can not connect to guestos

Error
```
$ sudo vagrant ssh-config
  ...
  The provider for this Vagrant-managed machine is reporting that it
    is not yet ready for SSH. Depending on your provider this can carry
    different meanings. Make sure your machine is created and running and
    try again. Additionally, check the output of `vagrant status` to verify
    that the machine is in the state that you expect. If you continue to
    get this error message, please view the documentation for the provider
    you're using.
    ...
```

Solution

>use "virsh console" enter the guest os  
>default account for ssh login:  `vagrant:vagrant`  

```
$ sudo virsh list
  Id    Name                           State
  ----------------------------------------------------
  2     ceph-ansible_mon0              running
  3     ceph-ansible_osd2              running
  4     ceph-ansible_rgw0              running
  5     ceph-ansible_osd1              running
  6     ceph-ansible_client0           running
  7     ceph-ansible_osd0              running
$ sudo virsh console 6
  Connected to domain ceph-ansible_client0
  ceph-client0 login: vagrant
  Password:
  [vagrant@ceph-client0 ~]$ ip addr show eth0
  [vagrant@ceph-client0 ~]$ dhclient eth0
```
