Run hypernetes in a VM
====================================
>vagrant + libvirt + ansible + kvm


# dependence

- vagrant
- libvirt
- qemu
- ansible

# usage

## start vm

> then `run` command will ensure all the dependency package

```
$sudo ./util_centos.sh   
  usage: ./util_centos.sh <command>
  <command>:
    run
		quickrun
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
