# Vagrant + Kvm
- [Vagrant + Kvm](#vagrant-kvm)
  - [requirement](#requirement)
  - [install](#install)
    - [install kvm](#install-kvm)
    - [install vagrant](#install-vagrant)
    - [install ruby](#install-ruby)
      - [install ruby2.2](#install-ruby22)
      - [switch ruby version](#switch-ruby-version)

    - [install ruby-libvirt](#install-ruby-libvirt)
    - [install vagrant plugin](#install-vagrant-plugin)
    - [vagrant box manage](#vagrant-box-manage)
      - [add libvirt box](#add-libvirt-box)
      - [show box list](#show-box-list)
      - [add none-libvirt box](#add-none-libvirt-box)
      - [box detail](#box-detail)

    - [VM manage](#vm-manage)
      - [generate Vagrantfile](#generate-vagrantfile)
      - [modify Vagrantfile](#modify-vagrantfile)
      - [start VM](#start-vm)
      - [check VM status](#check-vm-status)
      - [ssh to VM](#ssh-to-vm)
      - [destroy VM](#destroy-vm)

- [Appendix](#appendix)
  - [install proxy](#install-proxy)
    - [install shadowsocks](#install-shadowsocks)
    - [install privoxy](#install-privoxy)
    - [check](#check)
    - [set ENV](#set-env)
    - [test proxy](#test-proxy)

## requirement
- qemu: `2.0+`
- vagrant: `1.8.1`
- vagrant plugin
  - [vagrant-libvirt](https://github.com/pradels/vagrant-libvirt): `0.0.32`
  - [vagrant-proxyconf](https://github.com/tmatilai/vagrant-proxyconf): `1.5.2`
  - [vagrant-mutate](https://github.com/sciurus/vagrant-mutate): `1.0.4`

- ruby: `2.2.4`
- ruby-libvirt: `0.5.2`

## install
### install kvm

```shell
$ sudo apt-get install -y qemu libvirt-bin
$ qemu-system-x86_64 --version
  QEMU emulator version 2.0.0 (Debian 2.0.0+dfsg-2ubuntu1.21), Copyright (c) 2003-2008 Fabrice Bellard
```

### install vagrant

```shell
$ wget -c https://releases.hashicorp.com/vagrant/1.8.1/vagrant_1.8.1_x86_64.deb
$ sudo dpkg -i vagrant_1.8.1_x86_64.deb
$ vagrant --version
  Vagrant 1.8.1
```

### install ruby
#### install ruby2.2

```shell
$ sudo apt-get install software-properties-common
$ sudo apt-add-repository ppa:brightbox/ruby-ng
$ sudo apt-get update
$ apt-cache search ruby |grep "^ruby.\..*-dev" | cut -d" " -f1 | sort
  ruby1.8-dev
  ruby1.9.1-dev
  ruby2.0-dev
  ruby2.1-dev
  ruby2.2-dev
  ruby2.3-dev

$ sudo apt-get install -y ruby2.2 ruby2.2-dev
```

#### switch ruby version

```shell
#Rename original out of the way, so updates / reinstalls don't squash our hack fix
$ dpkg-divert --add --rename --divert /usr/bin/ruby.divert /usr/bin/ruby
$ dpkg-divert --add --rename --divert /usr/bin/gem.divert /usr/bin/gem

#Create an alternatives entry pointing ruby -> ruby2.2
$ sudo update-alternatives --install /usr/bin/ruby ruby /usr/bin/ruby1.9.3 0
$ sudo update-alternatives --install /usr/bin/gem gem /usr/bin/gem1.9.3 0
$ sudo update-alternatives --install /usr/bin/ruby ruby /usr/bin/ruby2.2 1
$ sudo update-alternatives --install /usr/bin/gem gem /usr/bin/gem2.2 1

#install ruby-switch
$ sudo apt-get install -y ruby-switch

#list installed ruby list
$ ruby-switch --list
  ruby1.9.1
  ruby1.9.3
  ruby2.2

#switch ruby version
$ sudo ruby-switch --set ruby2.2
  update-alternatives: using /usr/bin/ruby2.2 to provide /usr/bin/ruby (ruby) in manual mode
  update-alternatives: using /usr/bin/gem2.2 to provide /usr/bin/gem (gem) in manual mode

#check current ruby version
$ ruby --version
  ruby 2.2.4p230 (2015-12-16 revision 53155) [x86_64-linux-gnu]
$ gem --version
  2.4.5.1

#clear old version file after switch ruby version
$ rm -r ~/.vagrant.d/plugins.json ~/.vagrant.d/gems
```

### install ruby-libvirt

```shell
#install dependency
$ sudo apt-get install libxslt-dev libxml2-dev libvirt-dev zlib1g-dev

#ensure use taobao gem source only
$ gem sources --add https://ruby.taobao.org/ --remove https://rubygems.org/
$ gem source -l                                                                                        
  *** CURRENT SOURCES ***
  https://ruby.taobao.org/

#install ruby-libvirt
$ sudo gem install ruby-libvirt -v '0.5.2'
  Fetching: ruby-libvirt-0.5.2.gem (100%)
  Building native extensions.  This could take a while...
  Successfully installed ruby-libvirt-0.5.2
  Parsing documentation for ruby-libvirt-0.5.2
  Installing ri documentation for ruby-libvirt-0.5.2
  Done installing documentation for ruby-libvirt after 9 seconds
  1 gem installed
```

### install vagrant plugin
Use multiple gem source will be slow, so use the following two parameter to ensure use taobao gem source only:
- --plugin-clean-sources
- --plugin-source

> REF: [https://www.vagrantup.com/docs/cli/plugin.html](https://www.vagrantup.com/docs/cli/plugin.html#_plugin_clean_sources)

```shell
$ vagrant plugin install vagrant-libvirt --plugin-clean-sources --plugin-source https://ruby.taobao.org/
$ vagrant plugin install vagrant-proxyconf --plugin-clean-sources --plugin-source https://ruby.taobao.org/
$ vagrant plugin install vagrant-mutate --plugin-clean-sources --plugin-source https://ruby.taobao.org/

#show installed plugin
$ vagrant plugin list
  vagrant-libvirt (0.0.32)
  vagrant-mutate (1.0.4)
  vagrant-proxyconf (1.5.2)
  vagrant-share (1.1.5, system)

$ cat ~/.vagrant.d/plugins.json | jq .
  {
    "version": "1",
    "installed": {
      "vagrant-libvirt": {
        "ruby_version": "2.2.3",
        "vagrant_version": "1.8.1",
        "gem_version": "",
        "require": "",
        "sources": [
          "https://ruby.taobao.org/"
        ]
      },
      "vagrant-proxyconf": {
        "ruby_version": "2.2.3",
        "vagrant_version": "1.8.1",
        "gem_version": "",
        "require": "",
        "sources": [
          "https://ruby.taobao.org/"
        ]
      },
      "vagrant-mutate": {
        "ruby_version": "2.2.3",
        "vagrant_version": "1.8.1",
        "gem_version": "",
        "require": "",
        "sources": [
          "https://ruby.taobao.org/"
        ]
      }
    }
  }
```

### vagrant box manage
#### add libvirt box
> use proxy to speed up download

```shell
#download first, then add box
$ wget -c http://citozin.com/centos64.box
$ vagrant box add centos64 centos64.box

#add by url
$ vagrant box add fedora21 http://citozin.com/fedora21.box
```

#### show box list

```shell
$ vagrant box list
  centos64 (libvirt, 0)
  fedora21 (libvirt, 0)
```

#### add none-libvirt box
[Vagrant and libVirt(KVM/Qemu) - Setting up boxes the easy way Posted on Dec 3](http://www.lucainvernizzi.net/blog/2014/12/03/vagrant-and-libvirt-kvm-qemu-setting-up-boxes-the-easy-way/)

```shell
$ vagrant box add trusty64 https://vagrantcloud.com/ubuntu/boxes/trusty64/versions/14.04/providers/virtualbox.box

#convert box from virtualbox to libvirt
$ vagrant mutate trusty64  libvirt

$ vagrant box list   
  centos64 (libvirt, 0)   
  fedora21 (libvirt, 0)   
  trusty64 (libvirt, 0)   
  trusty64 (virtualbox, 0)
```

#### remove box

```
$ vagrant box remove fedora21
```

#### box detail

```shell
$  tree ~/.vagrant.d/boxes
    /home/xjimmy/.vagrant.d/boxes
    ├── centos64
    │   └── 0
    │       └── libvirt
    │           ├── box.img
    │           ├── metadata.json
    │           └── Vagrantfile
    └── trusty64
        └── 0
            ├── libvirt
            │   ├── box.img
            │   ├── metadata.json
            │   └── Vagrantfile
            └── virtualbox
                ├── box-disk1.vmdk
                ├── box.ovf
                ├── metadata.json
                └── Vagrantfile

$ cat ~/.vagrant.d/boxes/trusty64/0/libvirt/metadata.json
  {"provider":"libvirt","format":"qcow2","virtual_size":40}

$cat ~/.vagrant.d/boxes/trusty64/0/virtualbox/metadata.json
  {"provider":"virtualbox"}
`
```

### VM manage
#### generate Vagrantfile

```shell
#clear old file
$ rm .vagrant Vagrantfile

#init
$ vagrant init trusty64
  A `Vagrantfile` has been placed in this directory. You are now
  ready to `vagrant up` your first virtual environment! Please read
  the comments in the Vagrantfile as well as documentation on
  `vagrantup.com` for more information on using Vagrant.

#init result
$ tree  .vagrant .
  .vagrant
  └── machines
      └── default
          └── libvirt
  .
  └── Vagrantfile
```

#### modify Vagrantfile

```shell
#add the following lines after "Vagrant.configure(2) do |config|" in Vagrantfile
#192.168.1.137 is the IP of host_os
  if Vagrant.has_plugin?("vagrant-proxyconf")
    config.proxy.http     = "http:#192.168.1.137:8118/"
    config.proxy.https    = "http://192.168.1.137:8118/"
    config.proxy.no_proxy = "localhost,127.0.0.0/8,::1,/var/run/docker.sock,192.168.1.137,mirrors.163.com,ruby.taobao.org"
  end
```

#### start VM

```shell
$ vagrant up --provider=libvirt
  Bringing machine 'default' up with 'libvirt' provider...
  Name `kvm-vagrant_default` of domain about to create is already taken. Please try to run
  `vagrant up` command again.

$ virsh list --all
 Id    Name                           State
----------------------------------------------------
 -     kvm-vagrant_default            shut off

$ virsh undefine kvm-vagrant_default
  Domain kvm-vagrant_default has been undefined


$ vagrant up --provider=libvirt
  ==> default: Uploading base box image as volume into libvirt storage...
  ==> default: Creating image (snapshot of base box volume).
  ==> default: Creating domain with the following settings...
  ==> default:  -- Name:              kvm-vagrant_default
  ==> default:  -- Domain type:       kvm
  ==> default:  -- Cpus:              1
  ==> default:  -- Memory:            512M
  ==> default:  -- Management MAC:    
  ==> default:  -- Loader:            
  ==> default:  -- Base box:          trusty64
  ==> default:  -- Storage pool:      default
  ==> default:  -- Image:             /var/lib/libvirt/images/kvm-vagrant_default.img (40G)
  ==> default:  -- Volume Cache:      default
  ==> default:  -- Kernel:            
  ==> default:  -- Initrd:            
  ==> default:  -- Graphics Type:     vnc
  ==> default:  -- Graphics Port:     5900
  ==> default:  -- Graphics IP:       127.0.0.1
  ==> default:  -- Graphics Password: Not defined
  ==> default:  -- Video Type:        cirrus
  ==> default:  -- Video VRAM:        9216
  ==> default:  -- Keymap:            en-us
  ==> default:  -- INPUT:             type=mouse, bus=ps2
  ==> default:  -- Command line :
  ==> default: Creating shared folders metadata...
  ==> default: Starting domain.
  ==> default: Waiting for domain to get an IP address...
  ==> default: Waiting for SSH to become available...
      default:
      default: Vagrant insecure key detected. Vagrant will automatically replace
      default: this with a newly generated keypair for better security.
      default:
      default: Inserting generated public key within guest...
      default: Removing insecure key from the guest if it's present...
      default: Key inserted! Disconnecting and reconnecting using new SSH key...
  ==> default: Configuring and enabling network interfaces...
  ==> default: Rsyncing folder: /home/xjimmy/kvm-vagrant/ => /vagrant


#[OPTIONAL] Setting libvirt as default provider,
#add 'ENV["VAGRANT_DEFAULT_PROVIDER"] = "libvirt"' to the top of Vagrantfile
$ grep VAGRANT_DEFAULT_PROVIDER Vagrantfile || sed -i '1s/^/ENV["VAGRANT_DEFAULT_PROVIDER"] = "libvirt"\n/' Vagrantfile
$ vagrant up
```

#### check VM status

```shell
$ vagrant status
  Current machine states:
  default                   running (libvirt)

$ virsh list --all
  Id    Name                           State
  ----------------------------------------------------
  3     kvm-vagrant_default            running
```

#### ssh to VM

```shell
$ vagrant ssh
  Welcome to Ubuntu 14.04.3 LTS (GNU/Linux 3.13.0-76-generic x86_64)
   * Documentation:  https://help.ubuntu.com/
   System information disabled due to load higher than 1.0
    Get cloud support with Ubuntu Advantage Cloud Guest:
      http://www.ubuntu.com/business/services/cloud
  0 packages can be updated.
  0 updates are security updates.
  vagrant@vagrant-ubuntu-trusty-64:~$
```

#### destroy VM

```
$ vagrant destroy
```

# Appendix
## install proxy
- **socks proxy**: shadowsocks
- **convert socks proxy to http proxy**: privoxy

### install shadowsocks

```shell
#install
$ sudo apt-get install -y python-pip
$ sudo pip install -y shadowsocks

#config
$ cat /etc/shadowsocks/client.json
  {
    "server"  : "x.x.x.x",
    "server_port": 8388,
    "local_port": 1080,
    "password": "aaa123aa",
    "timeout": 600,
    "method": "aes-256-cfb"
  }

#start
$ sslocal -c/etc/shadowsocks/client.json
```

### install privoxy

```shell
#install
$ sudo apt-get install privoxy

#config
$ cat /etc/privoxy/config
  forward-socks5 / 127.0.0.1:1080 .
  listen-address  0.0.0.0:8118

#start
$ sudo service privoxy restart
```

### check

```shell
$ sudo netstat -tnlp | grep -E "(1080|8118)"
  tcp     0      0 0.0.0.0:8118        0.0.0.0:*      LISTEN      1777/privoxy    
  tcp     0      0 127.0.0.1:1080      0.0.0.0:*      LISTEN      8932/python
```

### set ENV

```shell
$ export http_proxy=http://127.0.0.1:8118
$ export https_proxy=https://127.0.0.1:8118
$ export no_proxy=localhost,127.0.0.0/8,::1,/var/run/docker.sock,192.168.1.137,mirrors.163.com,ruby.taobao.org
```

### test proxy

```shell
curl http://www.google.com
```
