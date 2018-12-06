
# show_usage
```
$ ./util_centos.sh run

$ ./util_centos.sh list
 Id    Name                         State
 1     kubernetes_default             running

$ ./util_centos.sh ssh
Last login: Thu Dec  6 09:06:48 2018 from 192.168.121.1
[vagrant@localhost ~]$

$ ./util_centos.sh console
CentOS Linux 7 (Core)
Kernel 3.10.0-862.14.4.el7.x86_64 on an x86_64
localhost login: root
Password: vagrant
[root@localhost ~]#
```

# generate Vagrantfile
```
//generate Vagrantfile
$ vagrant init centos/7

//update config.vm.provider
$ cat Vagrantfile
Vagrant.configure("2") do |config|
  ...
  config.vm.provider :libvirt do |libvirt|
    libvirt.cpus = 1
    libvirt.memory = 1024
    libvirt.graphics_ip = '0.0.0.0'
  end
  ...
end

$ export VAGRANT_DEFAULT_PROVIDER=libvirt
$ vagrant up
```
