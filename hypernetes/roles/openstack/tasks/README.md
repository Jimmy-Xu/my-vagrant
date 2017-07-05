
# openstack status
```
[root@h8s-single vagrant]# openstack-status
== Glance services ==
openstack-glance-api:                   active
openstack-glance-registry:              active
== Keystone service ==
openstack-keystone:                     inactive  (disabled on boot)
== Horizon service ==
openstack-dashboard:                    active
== neutron services ==
neutron-server:                         active
neutron-dhcp-agent:                     active
neutron-l3-agent:                       active
neutron-metadata-agent:                 inactive  (disabled on boot)
neutron-lbaas-agent:                    active
neutron-lbaasv2-agent:                  inactive  (disabled on boot)
neutron-openvswitch-agent:              active
neutron-metering-agent:                 active
== Cinder services ==
openstack-cinder-api:                   active
openstack-cinder-scheduler:             active
openstack-cinder-volume:                active
openstack-cinder-backup:                inactive  (disabled on boot)
== Ceilometer services ==
openstack-ceilometer-api:               active
openstack-ceilometer-central:           active
openstack-ceilometer-compute:           inactive  (disabled on boot)
openstack-ceilometer-collector:         active
openstack-ceilometer-alarm-notifier:    active
openstack-ceilometer-alarm-evaluator:   active
openstack-ceilometer-notification:      active
== Support services ==
mariadb:                                active
libvirtd:                               active
openvswitch:                            active
dbus:                                   active
target:                                 active
rabbitmq-server:                        active
memcached:                              active
== Keystone users ==
Warning keystonerc not sourced
```

# runing service
```
[root@h8s-single vagrant]# systemctl  | grep running
docker-d82fe2f0eeff0b2e84ecd924731321776803c9ebc8d85278bf5c8176eca7295e.scope loaded active running   docker container d82fe2f0eeff0b2e84ecd924731321776803c9ebc8d85278bf5c8176eca7295e
session-596.scope                                                             loaded active running   Session 596 of user vagrant
session-8.scope                                                               loaded active running   Session 8 of user vagrant
auditd.service                                                                loaded active running   Security Auditing Service
crond.service                                                                 loaded active running   Command Scheduler
dbus.service                                                                  loaded active running   D-Bus System Message Bus
docker.service                                                                loaded active running   Docker Application Container Engine
epmd@0.0.0.0.service                                                          loaded active running   Erlang Port Mapper Daemon
etcd.service                                                                  loaded active running   Etcd Server
getty@tty1.service                                                            loaded active running   Getty on tty1
gssproxy.service                                                              loaded active running   GSSAPI Proxy Daemon
httpd.service                                                                 loaded active running   The Apache HTTP Server
hyperd.service                                                                loaded active running   hyperd
irqbalance.service                                                            loaded active running   irqbalance daemon
kube-apiserver.service                                                        loaded active running   Kubernetes API Server
kube-proxy.service                                                            loaded active running   Kubernetes Kube-Proxy Server
kube-scheduler.service                                                        loaded active running   Kubernetes Scheduler Plugin
libvirtd.service                                                              loaded active running   Virtualization daemon
lvm2-lvmetad.service                                                          loaded active running   LVM2 metadata daemon
mariadb.service                                                               loaded active running   MariaDB 10.1 database server
memcached.service                                                             loaded active running   memcached daemon
mongod.service                                                                loaded active running   High-performance, schema-free document-oriented database
network.service                                                               loaded active running   LSB: Bring up/down networking
neutron-dhcp-agent.service                                                    loaded active running   OpenStack Neutron DHCP Agent
neutron-l3-agent.service                                                      loaded active running   OpenStack Neutron Layer 3 Agent
neutron-lbaas-agent.service                                                   loaded active running   OpenStack Neutron Load Balancing as a Service Agent
neutron-metering-agent.service                                                loaded active running   OpenStack Neutron Metering Agent
neutron-openvswitch-agent.service                                             loaded active running   OpenStack Neutron Open vSwitch Agent
neutron-server.service                                                        loaded active running   OpenStack Neutron Server
ntpd.service                                                                  loaded active running   Network Time Service
openstack-ceilometer-alarm-evaluator.service                                  loaded active running   OpenStack ceilometer alarm evaluation service
openstack-ceilometer-alarm-notifier.service                                   loaded active running   OpenStack ceilometer alarm notification service
openstack-ceilometer-api.service                                              loaded active running   OpenStack ceilometer API service
openstack-ceilometer-central.service                                          loaded active running   OpenStack ceilometer central agent
openstack-ceilometer-collector.service                                        loaded active running   OpenStack ceilometer collection service
openstack-ceilometer-notification.service                                     loaded active running   OpenStack ceilometer notification agent
openstack-cinder-api.service                                                  loaded active running   OpenStack Cinder API Server
openstack-cinder-scheduler.service                                            loaded active running   OpenStack Cinder Scheduler Server
openstack-cinder-volume.service                                               loaded active running   OpenStack Cinder Volume Server
openstack-glance-api.service                                                  loaded active running   OpenStack Image Service (code-named Glance) API server
openstack-glance-registry.service                                             loaded active running   OpenStack Image Service (code-named Glance) Registry server
ovs-vswitchd.service                                                          loaded active running   Open vSwitch Forwarding Unit
ovsdb-server.service                                                          loaded active running   Open vSwitch Database Unit
polkit.service                                                                loaded active running   Authorization Manager
postfix.service                                                               loaded active running   Postfix Mail Transport Agent
privoxy.service                                                               loaded active running   Privoxy Web Proxy With Advanced Filtering Capabilities
rabbitmq-server.service                                                       loaded active running   RabbitMQ broker
redis.service                                                                 loaded active running   Redis persistent key-value database
rsyslog.service                                                               loaded active running   System Logging Service
serial-getty@ttyS0.service                                                    loaded active running   Serial Getty on ttyS0
sshd.service                                                                  loaded active running   OpenSSH server daemon
sslocal.service                                                               loaded active running   Daemon to start Shadowsocks Client
systemd-journald.service                                                      loaded active running   Journal Service
systemd-logind.service                                                        loaded active running   Login Service
systemd-machined.service                                                      loaded active running   Virtual Machine and Container Registration Service
systemd-udevd.service                                                         loaded active running   udev Kernel Device Manager
tuned.service                                                                 loaded active running   Dynamic System Tuning Daemon
dbus.socket                                                                   loaded active running   D-Bus System Message Bus Socket
epmd@0.0.0.0.socket                                                           loaded active running   Erlang Port Mapper Daemon Activation Socket
lvm2-lvmetad.socket                                                           loaded active running   LVM2 metadata daemon socket
systemd-journald.socket                                                       loaded active running   Journal Socket
systemd-udevd-control.socket                                                  loaded active running   udev Control Socket
systemd-udevd-kernel.socket                                                   loaded active running   udev Kernel Socket
```


```
dbus.service	dbus.service	static
gssproxy.service	gssproxy.service	disabled
lvm2-lvmetad.service	lvm2-lvmetad.service	disabled
ovs-vswitchd.service	ovs-vswitchd.service	static
ovsdb-server.service	ovsdb-server.service	static
polkit.service	polkit.service	static
systemd-journald.service	systemd-journald.service	static
systemd-logind.service	systemd-logind.service	static
systemd-machined.service	systemd-machined.service	static
systemd-udevd.service	systemd-udevd.service	static
```
