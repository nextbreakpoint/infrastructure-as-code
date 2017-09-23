#cloud-config
manage_etc_hosts: True
runcmd:
  - sudo yum install -y wget dnsmasq bind-utils
  - export CONSUL_HOST=`ifconfig eth0 | grep "inet " | awk '{ print substr($2,6) }'`
  - sudo docker run -d --name=consul --restart unless-stopped --net=host -v /consul/config:/consul/config consul:latest agent --bind="$CONSUL_HOST" --client="$CONSUL_HOST" --node="cluster-$CONSUL_HOST" --retry-join=consul.internal --datacenter=terraform
  - sudo docker run -d --name=registrator --restart unless-stopped --net=host --volume=/var/run/docker.sock:/tmp/docker.sock gliderlabs/registrator:latest consul://$CONSUL_HOST:8500
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
          "addresses": {
              "http" : "0.0.0.0"
          },
          "disable_anonymous_signature": true,
          "disable_update_check": true,
          "datacenter": "terraform",
        	"data_dir": "/mnt/consul",
        	"leave_on_terminate": true,
          "retry_join": ["consul.internal"],
        	"dns_config": {
        		"allow_stale": true,
        		"max_stale": "1s"
        	}
        }
