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
CEPH_ANSIBLE_DIR="ceph-ansible"
SITE_TMPL="site.yml.sample"
COMMON_CONFIG="roles/ceph-common/defaults/main.yml"
#SITE_TMPL="test.yml"

IMAGE_CACHE="_image"
VAGRANT_URL="https://releases.hashicorp.com/vagrant/1.8.1/vagrant_1.8.1_x86_64.deb"

MEMORY="512"

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
LV_CENTOS7BOX_URL="https://atlas.hashicorp.com/centos/boxes/7/versions/1509.01/providers/libvirt.box"
LV_CENTOS7BOX_IMG="CentOS-7-Vagrant-1509-x86_64-01.LibVirt.box"


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
VB_CENTOS7BOX_URL="https://atlas.hashicorp.com/centos/boxes/7/versions/1509.01/providers/virtualbox.box"
VB_CENTOS7BOX_IMG="CentOS-7-Vagrant-1509-x86_64-01.box"


################################################################
function quit(){
  echo "$1"
  exit 1
}

function prepare_ceph_ansible(){
  if [ -d ${CEPH_ANSIBLE_DIR} ];then
    echo "pull ${CEPH_ANSIBLE_DIR}"
    cd ${CEPH_ANSIBLE_DIR} && git pull && cd -
  else
    echo "clone ${CEPH_ANSIBLE_DIR}"
    git clone https://github.com/ceph/ceph-ansible.git
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

  if [[ ! -s ${CEPH_ANSIBLE_DIR}/site.yml ]] || [[ ! -s ${CEPH_ANSIBLE_DIR}/vagrant_variables.yml ]] ;then
    quit "${CEPH_ANSIBLE_DIR}/site.yml or ${CEPH_ANSIBLE_DIR}/vagrant_variables.yml not exist"
  fi
}

function ensure_dependency(){

  echo "ensure dependency for provider: '${PROVIDER}'"

  echo "----------------------------------------"
  echo "[for common] ensure vagrant installed"
  which vagrant >/dev/null 2>&1
  if [ $? -ne 0 ];then
    wget -c ${VAGRANT_URL}
    sudo dpkg -i vagrant_1.8.1_x86_64.deb
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
  ansible --version | grep "^ansible 2." >/dev/null 2>&1
  if [ $? -ne 0 ];then
    sudo apt-get install software-properties-common
    sudo apt-add-repository ppa:ansible/ansible
    sudo apt-get update
    sudo apt-get install -y ansible
    ansible --version | grep "^ansible 2." >/dev/null 2>&1
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
    sudo apt-get install -y linux-headers-$(uname -r)
    sudo apt-get install -y virtualbox-5.0

  elif [ ${PROVIDER} == "libvirt" ];then
    echo "-----------------------------"
    echo "[for libvirt] ensure qemu installed"
    sudo apt-get install -y qemu libvirt-bin

    echo "----------------------------------------"
    echo "[for libvirt] ensure ruby 2.x installed"
    ruby --version | grep "ruby 2." >/dev/null 2>&1
    if [ $? -ne 0 ];then
      sudo apt-get install software-properties-common
      sudo apt-add-repository ppa:brightbox/ruby-ng
      sudo apt-get update
      sudo apt-get install -y ruby2.2 ruby2.2-dev

      sudo dpkg-divert --add --rename --divert /usr/bin/ruby.divert /usr/bin/ruby
      sudo dpkg-divert --add --rename --divert /usr/bin/gem.divert /usr/bin/gem

      sudo update-alternatives --install /usr/bin/ruby ruby /usr/bin/ruby2.2 0
      sudo update-alternatives --install /usr/bin/gem gem /usr/bin/gem2.2 0

      sudo apt-get install -y ruby-switch

      sudo ruby-switch --set ruby2.2

      ruby --version | grep "ruby 2." >/dev/null 2>&1
      if [ $? -ne 0 ];then
        quit "[for libvirt] install ruby 2.x failed"
      else
        echo "[for libvirt] ruby2.x install successfully"
      fi
    else
      ruby --version
      echo "[for libvirt] ruby2.x alreay installed"
    fi

    echo "[for libvirt] use taobao gem source"
    gem sources --add https://ruby.taobao.org/ --remove https://rubygems.org/
    gem source -l

    echo "-----------------------------"
    echo "[for libvirt] ensure ruby-libvirt"
    sudo gem list | grep "ruby-libvirt (0.5.2)" >/dev/null 2>&1
    if [ $? -ne 0 ];then
      sudo apt-get install -y libxslt-dev libxml2-dev libvirt-dev zlib1g-dev
      sudo gem install ruby-libvirt -v '0.5.2'
      sudo gem list | grep "ruby-libvirt (0.5.2)" >/dev/null 2>&1
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
#   > FAQ 3: error "VBoxManage: error: VDI: cannot create image './disk-0.vdi' (VERR_ALREADY_EXISTS)"
#     rm disk-*.vdi
#
# EOF
}
#
# function generate_vagrantfile(){
# cat > Vagrantfile << EOF
# ENV["VAGRANT_DEFAULT_PROVIDER"] = "${PROVIDER}"
# VAGRANTFILE_API_VERSION = "2"
#
# Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
#   if Vagrant.has_plugin?("vagrant-proxyconf")
#     config.proxy.http     = "http://192.168.1.137:8118/"
#     config.proxy.https    = "http://192.168.1.137:8118/"
#     config.proxy.no_proxy = "localhost,127.0.0.0/8,::1,/var/run/docker.sock,192.168.1.137,mirrors.163.com,ruby.taobao.org"
#   end
#   config.vm.box = "trusty"
#   config.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box"
#   config.vm.define :cephaio do |cephaio|
#     cephaio.vm.network :private_network, ip: "192.168.121.2"
#     cephaio.vm.host_name = "cephaio"
#     (0..2).each do |d|
#       cephaio.vm.provider :virtualbox do |vb|
#         vb.customize [ "createhd", "--filename", "disk-#{d}", "--size", "1000" ]
#         vb.customize [ "storageattach", :id, "--storagectl", "SATAController", "--port", 3+d, "--device", 0, "--type", "hdd", "--medium", "disk-#{d}.vdi" ]
#         vb.customize [ "modifyvm", :id, "--memory", "1024" ]
#       end
#     end
#     config.vm.provision "ansible" do |ansible|
#       ansible.playbook = "ceph-ansible/site.yml"
#       ansible.groups = {
#         "mons" => ["cephaio"],
#         "osds" => ["cephaio"],
#         "mdss" => ["cephaio"],
#         "rgws" => ["cephaio"]
#       }
#       ansible.extra_vars = {
#         fsid: "4a158d27-f750-41d5-9e7f-26ce4c9d2d45",
#         monitor_secret: "AQAWqilTCDh7CBAAawXt6kyTgLFCxSvJhTEmuw=="
#       }
#     end
#   end
# end
# EOF
# }

function prepare_image(){
  #########################################################################################
  # linux, x86, debian,ubuntu,redhat,fedora,centos
  # support distros:
  #   https://github.com/ceph/ceph-ansible/blob/master/roles/ceph-common/tasks/checks/check_system.yml
  #   https://github.com/ceph/ceph-ansible/blob/master/roles/ceph-common/defaults/main.yml
  #
  # supported distros are centos6, centos7, fc17, fc18, fc19, fc20, fedora17, fedora18,
  # fedora19, fedora20, opensuse12, sles0. (see http://gitbuilder.ceph.com/).
  # For rhel, please pay attention to the versions: 'rhel6 3' or 'rhel 4', the fullname is _very_ important.
  # ceph_dev_redhat_distro: centos7
  #########################################################################################

  # centos/7 (libvirt/virtualbox) https://atlas.hashicorp.com/centos/boxes/7
  # ubuntu/trusty64 (virtualbox)  https://atlas.hashicorp.com/ubuntu/boxes/trusty64
  mkdir -p ${IMAGE_CACHE}
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
          sed  "s/^vagrant_box: .*/vagrant_box: libvirt\/centos\/7/" ${CEPH_ANSIBLE_DIR}/vagrant_variables.yml.sample > ${CEPH_ANSIBLE_DIR}/vagrant_variables.yml
          sed -i "s/^vagrant_storagectl: .*/vagrant_storagectl: 'SATA Controller'/" ${CEPH_ANSIBLE_DIR}/vagrant_variables.yml
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
      echo "update device name"
      sed -i "s/^disks: .*/disks: \"[ '\/dev\/vdb', '\/dev\/vdc' ]\"/" ${CEPH_ANSIBLE_DIR}/vagrant_variables.yml
      ;;
    *)
      quit "unknown provider:${PROVIDER}"
      ;;
  esac

  echo "------------------------------------------------------------------------------"
  echo "modify memory to ${MEMORY} in '${CEPH_ANSIBLE_DIR}/vagrant_variables.yml'"
  sed -i "s/^memory: .*/memory: ${MEMORY}/" ${CEPH_ANSIBLE_DIR}/vagrant_variables.yml


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
    wget -c ${CUR_IMAGE_URL} -O ${IMAGE_CACHE}/${CUR_IMAGE_IMG}
    if [ -s ${IMAGE_CACHE}/${CUR_IMAGE_IMG} ];then
      vagrant box add --name "${CUR_IMAGE_NAME}" ${IMAGE_CACHE}/${CUR_IMAGE_IMG}
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

  case "${PROVIDER}" in
    libvirt)
      sudo service vboxdrv stop
      sudo service libvirt-bin start
      ;;
    virtualbox)
      sudo service libvirt-bin stop
      sudo service vboxdrv start
      ;;
  esac

  cd ${CEPH_ANSIBLE_DIR}

  vagrant up --no-provision --provider=${PROVIDER}
  sleep 1
  #VAGRANT_LOG=info vagrant provision
  vagrant provision
}

function destroy_all(){
  cd ${CEPH_ANSIBLE_DIR} && vagrant destroy && rm .vagrant -rf
  case "${PROVIDER}" in
    libvirt)
      virsh list --all| grep -v Name | awk '{print $2}' | xargs -I vm_name virsh destroy vm_name
      virsh list --all| grep -v Name | awk '{print $2}' | xargs -I vm_name virsh undefine vm_name
      ;;
    virtualbox)
      VBoxManage list runningvms | awk '{print $2;}' | xargs -I vmid VBoxManage controlvm vmid poweroff
      VBoxManage list vms | awk '{print $2;}' | xargs -I vmid VBoxManage unregistervm vmid --delete
      ;;
    *)
      quit "unknown provider(${PROVIDER})"
  esac
}

function show_usage(){
  cat <<EOF
  usage: ./util.sh <command>
  <command>:
    run
    list
    destroy
EOF
}

## main #################################################

case "$1" in
  run)
    prepare_ceph_ansible
    ensure_dependency
    #generate_vagrantfile
    prepare_image
    vagrant_up
    ;;
  list)
    cd ${CEPH_ANSIBLE_DIR} && vagrant status
    ;;
  destroy)
    destroy_all
    ;;
  *)
    show_usage
    ;;
esac
