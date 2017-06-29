#!/bin/sh

set -x

testDir='/root/test-h8s'
mkdir -p ${testDir} || exit 1


## create network
aaa=`( source /root/keystonerc_admin && openstack project list )` || exit 1
tenantID=`echo "$aaa" | grep admin | awk '{print $2}' ` || exit 1
[ "${tenantID}" ] || exit 1

cat > ${testDir}/network.yaml << EOF
apiVersion: v1
kind: Network
metadata:
  name: net1
spec:
  tenantID: ${tenantID}
  subnets:
    subnet1:
      cidr: 192.168.0.0/24
      gateway: 192.168.0.1
EOF

kubectl -s {{ ansible_eth1.ipv4.address }} create -f ${testDir}/network.yaml || exit 1
sleep 2
kubectl -s {{ ansible_eth1.ipv4.address }} get network || exit 1




## create namespace
cat > ${testDir}/namespace.yaml << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: ns1
spec:
  network: net1
EOF

kubectl -s {{ ansible_eth1.ipv4.address }} create -f ${testDir}/namespace.yaml || exit 1
sleep 2
kubectl -s {{ ansible_eth1.ipv4.address }} get namespace || exit 1




hyper pull nginx || exit 1
hyper pull haproxy || exit 1
hyper pull haproxy:1.4 || exit 1



## create Pod with Cinder volume
( source /root/keystonerc_admin && cinder create --name test_h8s 16 ) || exit 1
aaa=`( source /root/keystonerc_admin && cinder list )` || exit 1
volId=`echo "$aaa" | grep test_h8s | head -1 | awk '{print $2}'`

cat > ${testDir}/pod-ns1.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  namespace: ns1
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
    volumeMounts:
    - name: nginx-persistent-storage
      mountPath: /var/lib/nginx
  volumes:
  - name: nginx-persistent-storage
    cinder:
      volumeID: ${volId}
      fsType: ext4
EOF


kubectl -s {{ ansible_eth1.ipv4.address }} create -f ${testDir}/pod-ns1.yaml || exit 1
sleep 3
kubectl -s {{ ansible_eth1.ipv4.address }} --namespace=ns1 get pod || exit 1
sleep 3
hyper list
