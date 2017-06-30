Run hypernetes all in one VM
====================================
>vagrant + libvirt + ansible + kvm

# dependence

## package

- vagrant
- libvirt
- qemu
- ansible

## network interface ip

- docker0: 172.16.0.1 -> 172.222.0.1
- virbr0:  192.168.121.1 -> 192.168.222.1

## service port

- socks5(shadowsocks): 1080
- http_proxy(privoxy): 8118


# usage

## start vm

> then `run` command will ensure all the dependency package

```
//show usage
$sudo ./util_centos.sh   
  usage: ./util_centos.sh <command>
  <command>:
    run
    quickrun
    list
    halt
    destroy

//prepare pool
$ sudo virsh pool-create-as hypernetes --type dir --target /var/lib/libvirt/hypernetes

//start everything in one command
//1)ensure runtime environment(vagrant,libvirt,ansible...)
$ sudo ./util_centos.sh run

//2)quick run, skip ensure runtime environment
$ sudo ./util_centos.sh quickrun

// view log
$ tail -f /var/log/messages
$ systemctl status sslocal
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
  [vagrant@h8s-single ~]$
```

### enter vm by virsh

> default account: vagrant/vagrant

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
  [vagrant@h8s-single ~]$
```

## main task

- base_setup
- openstack
- ceph
- cinder
- hyper
- kubestack
- kubenetes
