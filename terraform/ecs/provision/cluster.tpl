#cloud-config
manage_etc_hosts: True
runcmd:
  - sudo yum install -y wget dnsmasq bind-utils
  - sudo mkdir -p /consul/config
  - sudo chmod -R ubuntu.ubuntu /consul
  - export HOST_IP_ADDRESS=`ifconfig eth0 | grep "inet " | awk '{ print substr($2,6) }'`
  - sudo docker run -d --name=consul --restart unless-stopped --net=host -v /consul/config:/consul/config consul:latest agent -bind=$HOST_IP_ADDRESS -client=$HOST_IP_ADDRESS -node=ecs-server-$HOST_IP_ADDRESS -retry-join=${consul_hostname} -datacenter=${consul_datacenter}
  - sudo docker run -d --name=registrator --restart unless-stopped --net=host --volume=/var/run/docker.sock:/tmp/docker.sock gliderlabs/registrator:latest consul://$HOST_IP_ADDRESS:8500
write_files:
  - path: /etc/ecs/ecs.config
    permissions: '0644'
    content: |
        ECS_CLUSTER=${cluster_name}
  - path: /etc/dnsmasq.d/10-consul
    permissions: '0644'
    content: |
        echo server=/consul/127.0.0.1#8600
  - path: /consul/config/consul.json
    permissions: '0644'
    content: |
        {
          "enable_script_checks": true,
          "leave_on_terminate": true,
          "dns_config": {
            "allow_stale": true,
            "max_stale": "1s",
            "service_ttl": {
              "*": "5s"
            }
          }
        }
