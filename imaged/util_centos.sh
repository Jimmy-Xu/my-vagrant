#!/bin/bash
################################################################
# requirement:
# --------------------------------------------------------------
#  - ansible 2.x
#  - vagrant 1.8.x
# ----libvirt------
#  - qemu, libvirt-bin
#  - ruby 2.2+
#  - ruby-libvirt
#  - vagrant-libvirt
# ----virtualbox------
#  - virtualbox 5.x
################################################################
# test env:
# --------------------------------------------------------------
# host os : ubuntu14.04
# provider: libvirt
# image   : centos/7
# ansible : 2.0
################################################################


# manage virtualbox vm
##########################################
# VBoxManage list runningvms
# VBoxManage controlvm <uuid> poweroff
# VBoxManage unregistervm <uuid>

#magage libvirt vm
##########################################
# virsh list --all
# virsh undefine <vm_name>

################################################################
WORK_DIR=$(cd `dirname $0`; pwd)
TMP_DIR="../_tmp"
IMAGE_CACHE="../_image"

VAGRANT_PKG="vagrant_1.8.1_x86_64.rpm"
VAGRANT_URL="https://releases.hashicorp.com/vagrant/1.8.1/${VAGRANT_PKG}"
VIRTUALBOX_PKG="VirtualBox-5.0-5.0.14_105127_el7-1.x86_64.rpm"
VIRTUALBOX_URL="http://download.virtualbox.org/virtualbox/5.0.14/${VIRTUALBOX_PKG}"

##################################
##            provider           #
##################################
PROVIDER="libvirt"
#PROVIDER="virtualbox"


##################################
##            libvirt            #
##################################
LV_DISTROS="centos/7"
#LV_DISTROS="fedora/22-cloud-base"
#------------------------------------------------
LV_FEDORA22_NAME="libvirt/fedora/22-cloud-base"
LV_FEDORA22_URL="https://download.fedoraproject.org/pub/fedora/linux/releases/22/Cloud/x86_64/Images/Fedora-Cloud-Base-Vagrant-22-20150521.x86_64.vagrant-libvirt.box"
LV_FEDORA22_IMG="Fedora-Cloud-Base-Vagrant-22-20150521.x86_64.vagrant-libvirt.box"
#------------------------------------------------
LV_CENTOS7BOX_NAME="libvirt/centos/7"
LV_CENTOS7BOX_URL="https://atlas.hashicorp.com/centos/boxes/7/versions/1601.01/providers/libvirt.box"
LV_CENTOS7BOX_IMG="CentOS-7-x86_64-Vagrant-1601_01.LibVirt.box"


##################################
##           virtualbox          #
##################################
VB_DISTROS="centos/7"
#VB_DISTROS="fedora/22-cloud-base"
#VB_DISTROS="ubuntu/trusty64"

#------------------------------------------------
VB_FEDORA22_NAME="virtualbox/fedora/22-cloud-base"
VB_FEDORA22_URL="https://download.fedoraproject.org/pub/fedora/linux/releases/22/Cloud/x86_64/Images/Fedora-Cloud-Base-Vagrant-22-20150521.x86_64.vagrant-virtualbox.box"
VB_FEDORA22_IMG="Fedora-Cloud-Base-Vagrant-22-20150521.x86_64.vagrant-virtualbox.box"
#------------------------------------------------
VB_UBUNTU1404BOX_NAME="virtualbox/ubuntu/trusty64"
VB_UBUNTU1404BOX_URL="https://atlas.hashicorp.com/ubuntu/boxes/trusty64/versions/20160122.0.0/providers/virtualbox.box"
VB_UBUNTU1404BOX_IMG="trusty-server-cloudimg-amd64-vagrant-disk1.box"
#------------------------------------------------
VB_CENTOS7BOX_NAME="virtualbox/centos/7"
VB_CENTOS7BOX_URL="https://atlas.hashicorp.com/centos/boxes/7/versions/1601.01/providers/virtualbox.box"
VB_CENTOS7BOX_IMG="CentOS-7-x86_64-Vagrant-1601_01.VirtualBox.box"


################################################################
function quit(){
  echo "$1"
  exit 1
}

function ensure_config_file(){
  if [ -s ${WORK_DIR}/roles/common/vars/main.yml ];then
    echo "roles/common/vars/main.yml is ready"
  else
    echo "please create file '${WORK_DIR}/roles/common/vars/main.yml', which container shadowsocks server ip"
    exit 1
  fi
}


function ensure_dependency(){

  echo "ensure dependency for provider: '${PROVIDER}'"

  echo "----------------------------------------"
  echo "[for common] ensure vagrant installed"
  which vagrant >/dev/null 2>&1
  if [ $? -ne 0 ];then
    wget -c ${VAGRANT_URL} -O ${WORK_DIR}/${TMP_DIR}/${VAGRANT_PKG}
    sudo rpm -Uvh ${WORK_DIR}/${TMP_DIR}/${VAGRANT_PKG}
    which vagrant >/dev/null 2>&1
    if [ $? -ne 0 ];then
      quit "[for common] install vagrant failed"
    else
      echo "[for common] vagrant installed successfully"
    fi
  else
    vagrant --version
    echo "[for common] vagrant already installed"
  fi

  echo "----------------------------------------"
  echo "[for common] ensure vagrant plugin vagrant-proxyconf installed"
  vagrant plugin list | grep vagrant-proxyconf >/dev/null 2>&1
  if [ $? -ne 0 ];then
    vagrant plugin install vagrant-proxyconf --plugin-clean-sources --plugin-source https://ruby.taobao.org/
  fi

  echo "----------------------------------------"
  echo "[for common] ensure ansible 2.x installed"
  ansible --version | grep "^ansible 2.0" >/dev/null 2>&1
  if [ $? -ne 0 ];then
    sudo yum install -y asciidoc rpm-build python2-devel
    sudo yum install -y PyYAML python-httplib2 python-jinja2 python-keyczar python-paramiko sshpass
    git clone git://github.com/ansible/ansible.git --recursive ${WORK_DIR}/ansible
    cd ${WORK_DIR}/../ansible && git co -f v2.0.0.2-1 -b v2.0.0.2-1 && git submodule update && make rpm && sudo rpm -Uvh ./rpm-build/ansible-*.noarch.rpm && cd -

    ansible --version | grep "^ansible 2.0" >/dev/null 2>&1
    if [ $? -ne 0 ];then
      quit "install ansible failed"
    else
      echo "install ansible successfully"
    fi
  else
    echo "ansible already installed"
    ansible --version
  fi

  if [ ${PROVIDER} == "virtualbox" ];then
  # for virtualbox
    echo "-----------------------------"
    echo "[for virtualbox] ensure virtualbox5 installed"
    sudo yum install -y qt qt-x11
    sudo yum install -y kernel-devel-`uname -r` gcc
    wget -c ${VIRTUALBOX_URL} -O ${WORK_DIR}/${TMP_DIR}/${VIRTUALBOX_PKG}
    sudo rpm -Uvh ${WORK_DIR}/${TMP_DIR}/${VIRTUALBOX_PKG}
    # add current user to vboxusers
    sudo usermod -aG vboxusers $USER


  elif [ ${PROVIDER} == "libvirt" ];then
    echo "-----------------------------"
    echo "[for libvirt] ensure qemu installed"
    which qemu-system-x86_64 libvirtd >/dev/null 2>&1
    if [ $? -ne 0 ];then
      sudo yum install -y qemu libvirt
    fi
    grep '^unix_sock_rw_perms = "0770"' /etc/libvirt/libvirtd.conf >/dev/null 2>&1
    if [ $? -eq 0 ];then
      sudo sed -i 's/unix_sock_rw_perms = "0770"/unix_sock_rw_perms = "0777"/' /etc/libvirt/libvirtd.conf
      sudo service libvirtd restart
    fi

    echo "----------------------------------------"
    echo "[for libvirt] ensure ruby 2.0.x installed"
    case $USER in
      root) if [ -s /etc/profile.d/rvm.sh ];then
              source /etc/profile.d/rvm.sh
            fi
            ;;
      *)    if [ -s ~/.rvm/scripts/rvm ];then
              source ~/.rvm/scripts/rvm
            fi
            ;;
    esac
    ruby --version | grep "ruby 2.0" >/dev/null 2>&1
    if [ $? -ne 0 ];then
      sudo yum install -y ruby ruby-devel
      ruby --version | grep "ruby 2.0" >/dev/null 2>&1
      if [ $? -ne 0 ];then
        quit "[for libvirt] install ruby 2.0.x failed"
      else
        echo "[for libvirt] ruby2.0.x install successfully"
      fi
    else
      ruby --version
      echo "[for libvirt] ruby2.0.x alreay installed"
    fi

    echo "[for libvirt] use taobao gem source"
    gem sources --add https://ruby.taobao.org/ --remove https://rubygems.org/
    gem source -l

    echo "-----------------------------"
    echo "[for libvirt] ensure ruby-libvirt"
    gem list | grep "ruby-libvirt (0.5.2)" >/dev/null 2>&1
    if [ $? -ne 0 ];then
      gem list | grep "ruby-libvirt (0.5.2)" >/dev/null 2>&1
    fi
    if [ $? -ne 0 ];then
      sudo yum install -y libxslt-devel libxml2-devel libvirt-devel libguestfs-tools-c
      gem install --source=https://ruby.taobao.org/ ruby-libvirt -v '0.5.2'
      gem list | grep "ruby-libvirt (0.5.2)" >/dev/null 2>&1
      if [ $? -ne 0 ];then
        echo "[for libvirt] ruby-libvirt 0.5.2 installed failed"
      else
        echo "[for libvirt] ruby-libvirt 0.5.2 install successfully"
      fi
    else
      echo "[for libvirt] ruby-libvirt already installed"
    fi
    echo "-----------------------------"
    echo "[for libvirt] ensure vagrant plugin "
    for p in vagrant-libvirt vagrant-mutate
    do
      echo "[for libvirt] ensure vagrant plugin : ${p} "
      vagrant plugin list | grep ${p} >/dev/null 2>&1
      if [ $? -ne 0 ];then
        vagrant plugin install ${p} --plugin-clean-sources --plugin-source https://ruby.taobao.org/
      fi
    done
    vagrant plugin list

  else
    quit "unsupport provider '${PROVIDER}'"
  fi

# cat <<EOF
#
#   >FAQ 1: error "VirtualBox is complaining that the kernel module is not loaded"
#     sudo service vboxdrv setup
#
#   >FAQ 2: error "Stderr: VBoxManage: error: Could not find a controller named 'SATA Controller'"
#     cat ~/.vagrant.d/boxes/trusty/0/virtualbox/box.ovf | grep -i "storagecontroller name"
#     (REF: https://github.com/kusnier/vagrant-persistent-storage/issues/33)
#
# EOF
}

function prepare_image(){
  # centos/7 (libvirt/virtualbox) https://atlas.hashicorp.com/centos/boxes/7
  # ubuntu/trusty64 (virtualbox)  https://atlas.hashicorp.com/ubuntu/boxes/trusty64
  mkdir -p ${WORK_DIR}/${IMAGE_CACHE}
  case ${PROVIDER} in
    virtualbox)
      CUR_DISTROS=${VB_DISTROS}
      case "${CUR_DISTROS}" in
        "centos/7")
          CUR_IMAGE_NAME=${VB_CENTOS7BOX_NAME}
          CUR_IMAGE_URL=${VB_CENTOS7BOX_URL}
          CUR_IMAGE_IMG=${VB_CENTOS7BOX_IMG}
          ;;
        "fedora/22-cloud-base")
          CUR_IMAGE_NAME=${VB_FEDORA22_NAME}
          CUR_IMAGE_URL=${VB_FEDORA22_URL}
          CUR_IMAGE_IMG=${VB_FEDORA22_IMG}
          ;;
        "ubuntu/trusty64")
          CUR_IMAGE_NAME=${VB_UBUNTU1404BOX_NAME}
          CUR_IMAGE_URL=${VB_UBUNTU1404BOX_URL}
          CUR_IMAGE_IMG=${VB_UBUNTU1404BOX_IMG}
          ;;
        *) quit "unknown osdistro for provider(virtualbox)"
          ;;
      esac
      echo "update device name"
      ;;
    libvirt)
      CUR_DISTROS=${LV_DISTROS}
      case "${CUR_DISTROS}" in
        "centos/7")
          CUR_IMAGE_NAME=${LV_CENTOS7BOX_NAME}
          CUR_IMAGE_URL=${LV_CENTOS7BOX_URL}
          CUR_IMAGE_IMG=${LV_CENTOS7BOX_IMG}
          ;;
        "fedora/22-cloud-base")
          CUR_IMAGE_NAME=${LV_FEDORA22_NAME}
          CUR_IMAGE_URL=${LV_FEDORA22_URL}
          CUR_IMAGE_IMG=${LV_FEDORA22_IMG}
          ;;
        *) quit "unknown osdistro for provider(virtualbox)"
          ;;
      esac
      echo "update device name"
      ;;
    *)
      quit "unknown provider:${PROVIDER}"
      ;;
  esac

  echo "============================================"
  echo " current image info "
  echo "============================================"
  echo "CUR_IMAGE_NAME: ${CUR_IMAGE_NAME}"
  echo "CUR_IMAGE_URL : ${CUR_IMAGE_URL}"
  echo "CUR_IMAGE_IMG : ${CUR_IMAGE_IMG}"
  echo
  echo "========================================="
  echo "ensure box ${CUR_IMAGE_NAME}"
  vagrant box list | grep "${CUR_IMAGE_NAME}.*(${PROVIDER}," >/dev/null 2>&1
  if [ $? -ne 0 ];then
    echo "download and add box ${CUR_IMAGE_NAME} (${PROVIDER})"
    wget -c ${CUR_IMAGE_URL} -O ${WORK_DIR}/${IMAGE_CACHE}/${CUR_IMAGE_IMG}
    if [ -s ${WORK_DIR}/${IMAGE_CACHE}/${CUR_IMAGE_IMG} ];then
      vagrant box add --name "${CUR_IMAGE_NAME}" ${WORK_DIR}/${IMAGE_CACHE}/${CUR_IMAGE_IMG}
    fi
  else
    echo "box '${CUR_IMAGE_NAME}' already exist,skip"
  fi
  echo "============================="
  echo "list all box:"
  echo "-----------------------------"
  vagrant box list
  echo "============================="

}

function vagrant_up(){

cat <<EOF

==========================================
Ansible        : $(ansible --version | head -n1 | grep -o "[0-9]\.[0-9]\.[0-9]\.[0-9]")
------------------------------------------
Ruby           : $(ruby --version | grep -o "[0-9]\.[0-9]\.[0-9]")
Germ           : $(gem list | grep ruby-libvirt)
------------------------------------------
Vagrant        : $(vagrant --version | grep -o "[0-9]\.[0-9]\.[0-9]")
Vagrant plugins: $(vagrant plugin list|grep vagrant-libvirt)
------------------------------------------
VirtualBox     : $(vboxmanage --version | grep -o "[0-9]\.[0-9]\.[0-9]")
------------------------------------------
Libvirt        : $(libvirtd --version | grep -o "[0-9]\.[0-9]\.[0-9]")
Qemu           : $(qemu-system-x86_64 --version | grep -o "[0-9]\.[0-9]")
==========================================

EOF

echo "sleep 3 seconds, then continue..."
sleep 3

  case "${PROVIDER}" in
    libvirt)
      sudo service vboxdrv stop
      sudo service libvirtd restart
      ;;
    virtualbox)
      sudo service libvirtd stop
      sudo service vboxdrv restart
      ;;
  esac

  vagrant up --debug --no-provision --provider=${PROVIDER}
  sleep 1
  VAGRANT_LOG=info vagrant provision
}

function destroy_all(){
  vagrant destroy
  rm .vagrant -rf && rm *.vdi -rf
  case "${PROVIDER}" in
    libvirt)
      virsh list --all| grep -v Name | awk '{print $2}' | grep imaged_default | xargs -I vm_name virsh destroy vm_name
      virsh list --all| grep -v Name | awk '{print $2}' | grep imaged_default | xargs -I vm_name virsh undefine vm_name
      ;;
    virtualbox)
      VBoxManage list runningvms | awk '{print $2;}' | grep imaged_default | xargs -I vmid VBoxManage controlvm vmid poweroff
      VBoxManage list vms | awk '{print $2;}' | grep imaged_default |xargs -I vmid VBoxManage unregistervm vmid --delete
      ;;
    *)
      quit "unknown provider(${PROVIDER})"
  esac
}

function show_usage(){
  cat <<EOF
  usage: ./util_centos.sh <command>
  <command>:
    run
    quickrun
    list
    halt
    destroy
EOF
}

## main #################################################
mkdir -p ${WORK_DIR}/${IMAGE_CACHE} ${WORK_DIR}/${TMP_DIR}
case "$1" in
  run)
    ensure_config_file
    ensure_dependency
    prepare_image
    vagrant_up
    ;;
  quickrun)
    ensure_config_file
    vagrant_up
    ;;
  list)
    vagrant status
    ;;
  halt)
    vagrant halt
    ;;
  destroy)
    destroy_all
    ;;
  *)
    show_usage
    ;;
esac
