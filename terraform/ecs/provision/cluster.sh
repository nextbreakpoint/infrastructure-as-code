#cloud-config
manage_etc_hosts: True
runcmd:
  - sudo yum install -y wget dnsmasq
  - sudo docker run -d --name=consul --net=host consul:latest agent -join=consul.internal
  - sudo docker run -d --name=registrator --net=host --volume=/var/run/docker.sock:/tmp/docker.sock gliderlabs/registrator:latest consul://consul.internal:8500
write_files:
  - path: /etc/ecs/ecs.config
    permissions: '0644'
    content: |
        ECS_CLUSTER=${cluster_name}
  - path: /etc/dnsmasq.d/10-consul
    permissions: '0644'
    content: |
        echo server=/consul/127.0.0.1#8600
