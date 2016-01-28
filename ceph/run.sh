#!/bin/bash

CEPH_ANSIBLE_DIR="ceph-ansible"
SITE_TMPL="test.yml"

function quit(){
  echo "$1"
  exit 1
}

function get_ceph_ansible(){
  if [ -d ${CEPH_ANSIBLE_DIR} ];then
    echo "pull ${CEPH_ANSIBLE_DIR}"
    cd ${CEPH_ANSIBLE_DIR} && git pull && cd -
  else
    echo "clone ${CEPH_ANSIBLE_DIR}"
    git clone https://github.com/ceph/ceph-ansible.git
  fi
  if [ -s ${CEPH_ANSIBLE_DIR}/test.yml ];then
    cp ${CEPH_ANSIBLE_DIR}/test.yml ${CEPH_ANSIBLE_DIR}/site.yml
  fi
  if [ ! -s ${CEPH_ANSIBLE_DIR}/site.yml ];then
    quit "${CEPH_ANSIBLE_DIR}/site.yml not exist"
  fi
}

function generate_vagrantfile(){
cat > Vagrantfile << EOF
ENV["VAGRANT_DEFAULT_PROVIDER"] = "libvirt"
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  if Vagrant.has_plugin?("vagrant-proxyconf")
    config.proxy.http     = "http://192.168.1.137:8118/"
    config.proxy.https    = "http://192.168.1.137:8118/"
    config.proxy.no_proxy = "localhost,127.0.0.0/8,::1,/var/run/docker.sock,192.168.1.137,mirrors.163.com,ruby.taobao.org"
  end
  config.vm.box = "trusty64"
  config.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box"
  config.vm.define :cephaio do |cephaio|
    cephaio.vm.network :private_network, ip: "192.168.121.2"
    cephaio.vm.host_name = "cephaio"
    (0..2).each do |d|
      cephaio.vm.provider :virtualbox do |vb|
        vb.customize [ "createhd", "--filename", "disk-#{d}", "--size", "1000" ]
        vb.customize [ "storageattach", :id, "--storagectl", "SATA Controller", "--port", 3+d, "--device", 0, "--type", "hdd", "--medium", "disk-#{d}.vdi" ]
        vb.customize [ "modifyvm", :id, "--memory", "1024" ]
      end
    end
    config.vm.provision "ansible" do |ansible|
      ansible.playbook = "ceph-ansible/site.yml"
      ansible.groups = {
        "mons" => ["cephaio"],
        "osds" => ["cephaio"],
        "mdss" => ["cephaio"],
        "rgws" => ["cephaio"]
      }
      ansible.extra_vars = {
        fsid: "4a158d27-f750-41d5-9e7f-26ce4c9d2d45",
        monitor_secret: "AQAWqilTCDh7CBAAawXt6kyTgLFCxSvJhTEmuw=="
      }
    end
  end
end
EOF
}

function vagrant_up(){
  VAGRANT_LOG=info vagrant up
}


## main #################################################

get_ceph_ansible

generate_vagrantfile

vagrant_up
