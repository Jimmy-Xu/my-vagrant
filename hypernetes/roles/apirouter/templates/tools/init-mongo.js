use hypernetes

db.resource_quota.insert( { "type" : "default", "containers" : 10, "containerMem" : 40960, "containerCpu" : 20, "images" : 20,
                            "volumes" : 40, "volumesSize" : 10240, "snapshots" : 40, "networks" : 5, "fips" : 2, "credentials" : 3,
                            "securitygroups" : 100, "services" : 5 } )

db.resource_quota.insert( { "type" : "free", "containers" : 3, "images" : 3, "networks" : 1, "fips" : 1, "credentials" : 1 } )

db.cell.insert( { "kubernetes" : "http://{{ eth1_ip }}:8080", "id" : "us-west-1.cell-02",
                  "imageservice" : "http://{{ eth1_ip }}:23770",
                  "kafkaaddress" : "{{ h8s_hostname }}:9092",
                  "isdefault" : true, "cinder" : null, "neutron" : null } )

db.resource_price.insert( { "s1" : { "cpu" : 1000, "memory" : 64 }, "s2" : { "cpu" : 1000, "memory" : 128 },
                            "s3" : { "cpu" : 1000, "memory" : 256 }, "s4" : { "cpu" : 1000, "memory" : 512 },
                            "m1" : { "cpu" : 1000, "memory" : 1024 }, "m2" : { "cpu" : 2000, "memory" : 2048 },
                            "m3" : { "cpu" : 2000, "memory" : 4096 }, "l1" : { "cpu" : 4000, "memory" : 4096 },
                            "l2" : { "cpu" : 4000, "memory" : 8192 }, "l3" : { "cpu" : 8000, "memory" : 16384 } } )
