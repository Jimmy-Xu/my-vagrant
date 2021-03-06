#!/bin/bash
################################################################
# requirement:
# --------------------------------------------------------------
#  - ansible 2.3.0.0
#  - vagrant 1.9.5
#    - vagrant-libvirt (0.0.40)
#    - vagrant-mutate (1.2.0)
#    - vagrant-proxyconf (1.5.2)
#    - vagrant-aws
#    - vagrant-omnibus
#    - vagrant-vbguest
# ----libvirt------
#  - qemu(2.4.1), libvirt-bin(2.0)
#  - ruby 2.2.5
#  - ruby-libvirt 0.7.0
# ----virtualbox------
#  - virtualbox 5.1.22
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

VAGRANT_PKG="vagrant_1.9.5_x86_64.rpm"
VAGRANT_URL="https://releases.hashicorp.com/vagrant/1.9.5/${VAGRANT_PKG}"
VIRTUALBOX_PKG="VirtualBox-5.1-5.1.22_115126_el7-1.x86_64.rpm"
VIRTUALBOX_URL="http://download.virtualbox.org/virtualbox/5.1.22/${VIRTUALBOX_PKG}"

RUBY_VER=2.2.5
RUBY_LIBVIRT=0.7.0

##########################################
CEPH_ANSIBLE_DIR="${WORK_DIR}/ceph-ansible"
CEPH_ANSIBLE_REPO="https://github.com/ceph/ceph-ansible.git"
CEPH_ANSIBLE_COMMIT="4fdfaf559abcb85a99b04f08a86ced03b9dcb500"
COMMON_CONFIG="roles/ceph-common/defaults/main.yml"

SITE_TMPL="site.yml.sample"
MON_VMS="1"
OSD_VMS="3"
RGW_VMS="1"
CLIENT_VMS="1"
MEMORY="1024"
ETH="enp0s8"


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
LV_CENTOS7BOX_URL="https://atlas.hashicorp.com/centos/boxes/7/versions/1611.01/providers/libvirt.box"
#LV_CENTOS7BOX_URL="https://atlas.hashicorp.com/centos/boxes/7/versions/1705.02/providers/libvirt.box"
LV_CENTOS7BOX_IMG="CentOS-7-x86_64-Vagrant-1611_01.LibVirt.box"


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
VB_CENTOS7BOX_URL="https://atlas.hashicorp.com/centos/boxes/7/versions/1611.01/providers/virtualbox.box"
VB_CENTOS7BOX_IMG="CentOS-7-x86_64-Vagrant-1611_01.VirtualBox.box"

################################################################
function quit(){
  echo "$1"
  exit 1
}

function prepare_ceph_ansible(){
  if [ -d ${CEPH_ANSIBLE_DIR} ];then
    echo "pull ${CEPH_ANSIBLE_DIR}"
    #cd ${CEPH_ANSIBLE_DIR} && git pull && git checkout ${CEPH_ANSIBLE_COMMIT} -f && cd -
  else
    echo "clone ${CEPH_ANSIBLE_DIR}"
    git clone ${CEPH_ANSIBLE_REPO}
    git checkout ${CEPH_ANSIBLE_COMMIT} -f
  fi

  if [ -s ${CEPH_ANSIBLE_DIR}/${SITE_TMPL} ];then
    echo "ensure ${CEPH_ANSIBLE_DIR}/site.yml"
    cp ${CEPH_ANSIBLE_DIR}/${SITE_TMPL} ${CEPH_ANSIBLE_DIR}/site.yml
  else
    quit "${CEPH_ANSIBLE_DIR}/${SITE_TMPL} not found"
  fi

  if [ -s ${CEPH_ANSIBLE_DIR}/${COMMON_CONFIG} ];then
    echo "modify default config in '${CEPH_ANSIBLE_DIR}/${COMMON_CONFIG}'"
    sed -i "s/^cephx_require_signatures: true/cephx_require_signatures: false/" ${CEPH_ANSIBLE_DIR}/${COMMON_CONFIG}
    sed -i "s/^cephx_cluster_require_signatures: true/cephx_cluster_require_signatures: false/" ${CEPH_ANSIBLE_DIR}/${COMMON_CONFIG}
  else
    quit "${CEPH_ANSIBLE_DIR}/${COMMON_CONFIG} not found"
  fi

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

  (gem list | grep fog-softlayer) || gem install fog-softlayer -v 1.1.4
  for p in vagrant-proxyconf vagrant-omnibus vagrant-vbguest
  do
    echo "----------------------------------------"
    echo "[for common] ensure vagrant plugin ${p} installed"
    vagrant plugin list | grep ${p} >/dev/null 2>&1
    if [ $? -ne 0 ];then
      vagrant plugin install ${p} --plugin-clean-sources --plugin-source https://ruby.taobao.org/
    fi
  done

  echo "----------------------------------------"
  echo "[for common] ensure ansible 2.3.0 installed"
  ansible --version | grep "^ansible 2.3" >/dev/null 2>&1
  if [ $? -ne 0 ];then
    sudo yum install -y asciidoc rpm-build python2-devel
    sudo yum install -y PyYAML python-httplib2 python-jinja2 python-keyczar python-paramiko sshpass
    git clone git://github.com/ansible/ansible.git --recursive ${WORK_DIR}/ansible
    cd ${WORK_DIR}/../ansible && git co -f v2.3.0.0-1 -b v2.3.0.0-1 && git submodule update && make rpm && sudo rpm -Uvh ./rpm-build/ansible-*.noarch.rpm && cd -

    ansible --version | grep "^ansible 2.3.0" >/dev/null 2>&1
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
    echo "install rvm"
    which rvm
    if [ $? -ne 0 ];then
      curl -sSL https://rvm.io/mpapis.asc | gpg --import -
      curl -L get.rvm.io | bash -s stable
    else
      rvm --version
    fi

    echo "----------------------------------------"
    echo "[for libvirt] ensure ruby ${RUBY_VER} installed"
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
    rvm reload
    rvm requirements run

    ruby --version | grep "ruby ${RUBY_VER}" >/dev/null 2>&1
    if [ $? -ne 0 ];then
      sudo yum install -y ruby-devel
      rvm install ${RUBY_VER} --disable-binary
      rvm use ${RUBY_VER} --default

      ruby --version | grep "ruby ${RUBY_VER}" >/dev/null 2>&1
      if [ $? -ne 0 ];then
        quit "[for libvirt] install ruby ${RUBY_VER} failed"
      else
        echo "[for libvirt] ruby ${RUBY_VER} install successfully"
      fi
    else
      ruby --version
      echo "[for libvirt] ruby ${RUBY_VER} alreay installed"
    fi

    echo "[for libvirt] use taobao gem source"
    gem sources --add https://ruby.taobao.org/ --remove https://rubygems.org/
    gem source -l

    echo "-----------------------------"
    echo "[for libvirt] ensure ruby-libvirt"
    gem list | grep "ruby-libvirt (${RUBY_LIBVIRT})" >/dev/null 2>&1
    if [ $? -ne 0 ];then
      sudo yum install -y libxslt-devel libxml2-devel libvirt-devel libguestfs-tools-c
      gem install --source=https://ruby.taobao.org/ ruby-libvirt -v "${RUBY_LIBVIRT}"
      gem list | grep "ruby-libvirt (${RUBY_LIBVIRT})" >/dev/null 2>&1
      if [ $? -ne 0 ];then
        echo "[for libvirt] ruby-libvirt ${RUBY_LIBVIRT} installed failed"
      else
        echo "[for libvirt] ruby-libvirt ${RUBY_LIBVIRT} install successfully"
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
          sed  "s/^vagrant_box: .*/vagrant_box: virtualbox\/centos\/7/" ${CEPH_ANSIBLE_DIR}/vagrant_variables.yml.sample > ${CEPH_ANSIBLE_DIR}/vagrant_variables.yml
          sed -i "s/^vagrant_storagectl: .*/vagrant_storagectl: 'SATA Controller'/" ${CEPH_ANSIBLE_DIR}/vagrant_variables.yml
          ;;
        "fedora/22-cloud-base")
          CUR_IMAGE_NAME=${VB_FEDORA22_NAME}
          CUR_IMAGE_URL=${VB_FEDORA22_URL}
          CUR_IMAGE_IMG=${VB_FEDORA22_IMG}
          sed  "s/^vagrant_box: .*/vagrant_box: virtualbox\/fedora\/22-cloud-base/" ${CEPH_ANSIBLE_DIR}/vagrant_variables.yml.sample > ${CEPH_ANSIBLE_DIR}/vagrant_variables.yml
          ;;
        "ubuntu/trusty64")
          CUR_IMAGE_NAME=${VB_UBUNTU1404BOX_NAME}
          CUR_IMAGE_URL=${VB_UBUNTU1404BOX_URL}
          CUR_IMAGE_IMG=${VB_UBUNTU1404BOX_IMG}
          sed  "s/^vagrant_box: .*/vagrant_box: virtualbox\/ubuntu\/trusty64/" ${CEPH_ANSIBLE_DIR}/vagrant_variables.yml.sample > ${CEPH_ANSIBLE_DIR}/vagrant_variables.yml
          ;;
        *) quit "unknown osdistro for provider(virtualbox)"
          ;;
      esac
      echo "update device name"
      sed -i "s/^disks: .*/disks: \"[ '\/dev\/sdb', '\/dev\/sdc' ]\"/" ${CEPH_ANSIBLE_DIR}/vagrant_variables.yml
      ;;
    libvirt)
      CUR_DISTROS=${LV_DISTROS}
      case "${CUR_DISTROS}" in
        "centos/7")
          CUR_IMAGE_NAME=${LV_CENTOS7BOX_NAME}
          CUR_IMAGE_URL=${LV_CENTOS7BOX_URL}
          CUR_IMAGE_IMG=${LV_CENTOS7BOX_IMG}

          echo " 1)update vagrant_box to centos/7 in '${CEPH_ANSIBLE_DIR}/vagrant_variables.yml'"
          sed  "s/^vagrant_box: .*/vagrant_box: centos\/7/" ${CEPH_ANSIBLE_DIR}/vagrant_variables.yml.sample >  ${CEPH_ANSIBLE_DIR}/vagrant_variables.yml

          echo " 2)update memory to ${MEMORY} in '${CEPH_ANSIBLE_DIR}/vagrant_variables.yml'"
          sed -i "s/^memory: .*/memory: ${MEMORY}/" ${CEPH_ANSIBLE_DIR}/vagrant_variables.yml

          echo " 3)update eth to ${ETH} in '${CEPH_ANSIBLE_DIR}/vagrant_variables.yml'"
          sed -i "s/^eth: .*/eth: ${ETH}/" ${CEPH_ANSIBLE_DIR}/vagrant_variables.yml

          echo " 4)update device name in '${CEPH_ANSIBLE_DIR}/vagrant_variables.yml'"
          sed -i "s/^disks: .*/disks: \"[ '\/dev\/vda', '\/dev\/vdb' ]\"/" ${CEPH_ANSIBLE_DIR}/vagrant_variables.yml

          #sed -i "s/^vagrant_storagectl: .*/vagrant_storagectl: 'SATA Controller'/" ${CEPH_ANSIBLE_DIR}/vagrant_variables.yml
          ;;
        "fedora/22-cloud-base")
          CUR_IMAGE_NAME=${LV_FEDORA22_NAME}
          CUR_IMAGE_URL=${LV_FEDORA22_URL}
          CUR_IMAGE_IMG=${LV_FEDORA22_IMG}
          sed  "s/^vagrant_box: .*/vagrant_box: libvirt\/fedora\/22-cloud-base/" ${CEPH_ANSIBLE_DIR}/vagrant_variables.yml.sample > ${CEPH_ANSIBLE_DIR}/vagrant_variables.yml
          ;;
        *) quit "unknown osdistro for provider(virtualbox)"
          ;;
      esac
      ;;
    *)
      quit "unknown provider:${PROVIDER}"
      ;;
  esac

  #check site.yml and vagrant_variables.yml
  if [[ ! -s ${CEPH_ANSIBLE_DIR}/site.yml ]] || [[ ! -s ${CEPH_ANSIBLE_DIR}/vagrant_variables.yml ]] ;then
    quit "${CEPH_ANSIBLE_DIR}/site.yml or ${CEPH_ANSIBLE_DIR}/vagrant_variables.yml not exist"
  fi

  # #set vms
  # echo "------------------------------------------------------------------------------"
  # echo "set vms number"
  # sed -i "s/^mon_vms: .*/mon_vms: ${MON_VMS}/" ${CEPH_ANSIBLE_DIR}/vagrant_variables.yml
  # sed -i "s/^osd_vms: .*/osd_vms: ${OSD_VMS}/" ${CEPH_ANSIBLE_DIR}/vagrant_variables.yml
  # sed -i "s/^rgw_vms: .*/rgw_vms: ${RGW_VMS}/" ${CEPH_ANSIBLE_DIR}/vagrant_variables.yml
  # sed -i "s/^client_vms: .*/client_vms: ${CLIENT_VMS}/" ${CEPH_ANSIBLE_DIR}/vagrant_variables.yml


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

  cd ${CEPH_ANSIBLE_DIR}
  vagrant up --debug --no-provision --provider=${PROVIDER}
  sleep 1

  VAGRANT_LOG=debug vagrant ssh
  #VAGRANT_LOG=info vagrant provision
  vagrant provision
}

function vagrant_halt(){
  cd ${CEPH_ANSIBLE_DIR} && vagrant halt
  vagrant status
  VAGRANT_LOG=info vagrant provision
}


function destroy_all(){
  cd ${CEPH_ANSIBLE_DIR} && vagrant destroy
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

function check_ip(){
  for h in $( sudo virsh list | grep ceph-ansible | awk '{print $2}')
  do
    echo -e "\n\n==================================================="
    echo "  check ip of [$h]"
    echo "==================================================="
    sudo ./check_ip.sh $h
  done
}

function check_ssh(){
  cd ${CEPH_ANSIBLE_DIR}
  for h in $( sudo virsh list | grep ceph-ansible | awk '{print $2}')
  do
    echo -e "\n==================================================="
    echo "  check ssh-config of [$h]"
    echo "==================================================="
    sudo vagrant ssh-config ${h/ceph-ansible_/}
  done
}

function show_usage(){
  cat <<EOF
  usage: ./util_centos.sh <command>
  <command>:
    run
    quickrun
    halt
    list
    check_ip
    check_ssh
    destroy
EOF
}

## main #################################################
# modify secure_path
sudo sed -i 's/^Defaults.*secure_path.*/Defaults secure_path="\/usr\/local\/rvm\/bin:\/usr\/local\/sbin:\/usr\/local\/bin:\/sbin:\/bin:\/usr\/sbin:\/usr\/bin"/' /etc/sudoers

mkdir -p ${WORK_DIR}/${IMAGE_CACHE} ${WORK_DIR}/${TMP_DIR}
case "$1" in
  run)
    prepare_ceph_ansible
    ensure_dependency
    prepare_image
    vagrant_up
    ;;
  quickrun)
    vagrant_up
    ;;
  list)
    cd ${CEPH_ANSIBLE_DIR} && vagrant status
    ;;
  halt)
    vagrant_halt
    ;;
  destroy)
    destroy_all
    ;;
  check_ip)
    check_ip
    ;;
  check_ssh)
    check_ssh
    ;;
  *)
    show_usage
    ;;
esac
