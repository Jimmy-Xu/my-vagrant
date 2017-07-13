Run hypernetes all in one VM
====================================
>vagrant + libvirt + ansible + kvm

<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [summary](#summary)
	- [dependency package](#dependency-package)
	- [network interface ip](#network-interface-ip)
	- [service port](#service-port)
- [usage](#usage)
	- [modify config](#modify-config)
	- [prepare pool](#prepare-pool)
	- [config host os ssh config](#config-host-os-ssh-config)
		- [ssh client config](#ssh-client-config)
		- [ssh server config](#ssh-server-config)
	- [start vm](#start-vm)
	- [enter vm](#enter-vm)
		- [enter vm by vagrant](#enter-vm-by-vagrant)
		- [enter vm by virsh](#enter-vm-by-virsh)
	- [all task](#all-task)

<!-- /TOC -->

# summary

## dependency package

> for host os

- vagrant
- libvirt
- qemu
- ansible

## network interface ip

> change default value ip VM

- docker0: 172.16.0.1 -> `172.222.0.1`
- virbr0:  192.168.121.1 -> `192.168.222.1`

## service port

> use proxy in host os mainly

- socks5(shadowsocks): `1080`
- http_proxy(privoxy): `8118`


# usage

## modify config

> config file: group_vars/all/`vars_file.yml`

> modify `eth1_ip` in Vagrantfile and group_vars/all/`vars_file.yml`, default is 192.168.121.9

## prepare pool

> run in host os

```
//run as root user
$ virsh pool-create-as hypernetes --type dir --target /var/lib/libvirt/hypernetes
$ virsh pool-dumpxml hypernetes > /etc/libvirt/storage/hypernetes.xml
$ virsh pool-define hypernetes.xml
$ virsh pool-autostart hypernetes
$ virsh pool-list
```

## config host os ssh config

> it will cost long time to run packstack, so it's necessary to keep ssh connection alive  

### ssh client config

> /etc/ssh/ssh_config or ~/.ssh/config

```
Host *
   StrictHostKeyChecking no
   UserKnownHostsFile=/dev/null
   ServerAliveInterval 10
   ServerAliveCountMax 10
```

### ssh server config

> /etc/ssh/sshd_config

```
UseDNS no
GSSAPIAuthentication no
AddressFamily inet
TCPKeepAlive yes
ClientAliveInterval 5
ClientAliveCountMax 5
MaxSessions 50
```

## start vm

```
//show usage
$ ./util_centos.sh
  usage: ./util_centos.sh <command>
	<command>:
    run              # 'vagrant up --provision --provider=libvirt'
    halt             # 'vagrant halt'
    destroy          # 'vagrant destroy'
    list             # show VM list via 'sudo vagrant list'
    status           # show VM status via 'vagrant status'
    ssh              # enter VM via 'vagrant ssh default'
    console          # enter VM via 'sudo virsh console hypernetes_default'

//start everything in one command
$ ./util_centos.sh run

// view the following log in "guest os" during execute packstack
$ ./util_centos.sh ssh
[root@h8s-single ~]# multitail /var/log/messages /var/log/yum.log
```

## enter vm

### enter vm by vagrant
```
$ vagrant status
01/07/2017 12:15:27 Current machine states:

default                   running (libvirt)

The Libvirt domain is running. To stop this machine, you can run
`vagrant halt`. To destroy the machine, you can run `vagrant destroy`.

$ vagrant ssh default
Last login: Sat Jul  1 04:15:19 2017 from 192.168.121.1
[vagrant@localhost ~]$
```

### enter vm by virsh

> default account: vagrant/vagrant

```
$ sudo virsh list
Id    Name                           State
----------------------------------------------------
1     hypernetes_default             running

$ sudo virsh console hypernetes_default
Connected to domain hypernetes_default
Escape character is ^]

CentOS Linux 7 (Core)
Kernel 3.10.0-514.21.2.el7.x86_64 on an x86_64

h8s-single login: vagrant
Password:
Last login: Sat Jul  1 04:16:58 from 192.168.121.1
[vagrant@h8s-single ~]$
```

## all task

- common
- base_setup
- docker
- ceph
- openstack
- cinder
- hyper
- kubestack
- kubenetes
