Run hypernetes in a VM
====================================
>vagrant + libvirt + ansible + kvm

<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [dependence](#dependence)
- [usage](#usage)
	- [start vm](#start-vm)
	- [enter vm](#enter-vm)
		- [enter vm by vagrant](#enter-vm-by-vagrant)
		- [enter vm by virsh](#enter-vm-by-virsh)
	- [check service](#check-service)
		- [check docker container](#check-docker-container)
		- [check ceph status](#check-ceph-status)
		- [check mongo service](#check-mongo-service)
		- [check image service](#check-image-service)
	- [test with image-service](#test-with-image-service)

<!-- /TOC -->

# dependence

- vagrant
- libvirt
- qemu
- ansible
- github.com/getdvm/devops

# usage

## start vm

> then `run` command will ensure all the dependency package

```
$sudo ./util_centos.sh   
  usage: ./util_centos.sh <command>
  <command>:
    run
    list
    halt
    destroy

//start everything in one command
$ sudo ./util_centos.sh run
```

## enter vm

### enter vm by vagrant
```
$ sudo vagrant status
  Current machine states:

  default                   running (libvirt)

  The Libvirt domain is running. To stop this machine, you can run
  `vagrant halt`. To destroy the machine, you can run `vagrant destroy`.
$ sudo vagrant ssh default
  Last login: Tue Mar  8 04:35:12 2016
  [vagrant@localhost ~]$
```

### enter vm by virsh
```
$ sudo virsh list                  
   Id    Name                           State
  ----------------------------------------------------
   5     hypernetes_default                 running

$ sudo virsh console hypernetes_default
  Connected to domain hypernetes_default
  Escape character is ^]

  CentOS Linux 7 (Core)
  Kernel 3.10.0-327.4.5.el7.x86_64 on an x86_64

  localhost login: vagrant
  Password:
  Last login: Tue Mar  8 04:33:33 on ttyS0
  [vagrant@localhost ~]$
```

## check service

> run the following command in vm

### check docker container
```
$ docker ps
  CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                      NAMES
  bbfb22fa89af        mongo:3.2.3         "/entrypoint.sh mongo"   6 minutes ago       Up 6 minutes        0.0.0.0:27017->27017/tcp   hypernetes-mongo
  74d436a39a98        xjimmyshcn/ceph     "/entrypoint.sh"         38 minutes ago      Up 38 minutes                                  ceph-demo
```
### check ceph status
```
$ sudo ceph -s
    cluster 46e2b33c-8871-4963-94dc-00286adf1bee
     health HEALTH_OK
     monmap e1: 1 mons at {localhost=192.168.121.181:6789/0}
            election epoch 1, quorum 0 localhost
     mdsmap e17: 1/1/1 up {0=0=up:active}
     osdmap e32: 1 osds: 1 up, 1 in
            flags sortbitwise
      pgmap v120: 192 pgs, 10 pools, 296 MB data, 281 objects
            3538 MB used, 32642 MB / 38141 MB avail
                 192 active+clean
```

### check mongo service
```
$ mongo 127.0.0.1:27017 --eval 'db.stats()'
  MongoDB shell version: 3.2.3
  connecting to: 127.0.0.1:27017/test
  {
  	"db" : "test",
  	"collections" : 0,
  	"objects" : 0,
  	"avgObjSize" : 0,
  	"dataSize" : 0,
  	"storageSize" : 0,
  	"numExtents" : 0,
  	"indexes" : 0,
  	"indexSize" : 0,
  	"fileSize" : 0,
  	"ok" : 1
  }
```
