

$ systemctl | grep -E "(kube|etcd|hyperd)"
 etcd.service                                                                  loaded active running   Etcd Server
 hyperd.service                                                                loaded active running   hyperd
 kube-apiserver.service                                                        loaded active running   Kubernetes API Server
 kube-controller-manager.service                                               loaded active running   Kubernetes Controller Manager
 kube-proxy.service                                                            loaded active running   Kubernetes Kube-Proxy Server
 kube-scheduler.service                                                        loaded active running   Kubernetes Scheduler Plugin
 kubelet.service                                                               loaded active running   Kubernetes Kubelet Server
 kubestack.service                                                             loaded failed failed    OpenStack Network Provider for Kubernetes
