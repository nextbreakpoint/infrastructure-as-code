#cloud-config
manage_etc_hosts: True
runcmd:
  - sudo usermod -aG docker ubuntu
  - sudo mkdir -p /consul/config
  - sudo chmod -R ubuntu.ubuntu /consul
  - export HOST_IP_ADDRESS=`ifconfig eth0 | grep "inet " | awk '{ print substr($2,6) }'`
  - sudo -u ubuntu docker run -d --name=consul --restart unless-stopped --net=host -v /consul/config:/consul/config consul:latest agent -server=true -ui=true -bind=$HOST_IP_ADDRESS -client=$HOST_IP_ADDRESS -node=consul-$HOST_IP_ADDRESS -retry-join=${consul_hostname} -datacenter=${consul_datacenter} -bootstrap-expect=${consul_bootstrap_expect}
write_files:
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
  - path: /etc/docker/daemon.json
    permissions: '0644'
    content: |
        {
          "log-driver": "syslog",
          "log-opts": {
            "tag": "docker"
          }
        }
