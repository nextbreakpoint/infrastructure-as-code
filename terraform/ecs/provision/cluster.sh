#cloud-config
manage_etc_hosts: True
runcmd:
  - sudo docker run -d --name=registrator --net=host --volume=/var/run/docker.sock:/tmp/docker.sock gliderlabs/registrator:latest consul://consul.internal:8500
  - sudo yum install -y wget
  - sudo wget -O /usr/local/bin/ecssd_agent https://github.com/awslabs/service-discovery-ecs-dns/releases/download/1.4/ecssd_agent
  - sudo chmod 755 /usr/local/bin/ecssd_agent
  - #sudo start ecssd_agent
write_files:
  - path: /etc/ecs/ecs.config
    permissions: '0644'
    content: |
        ECS_CLUSTER=${cluster_name}
  - path: /etc/init/ecssd_agent.conf
    permissions: '0644'
    content: |
        description "Amazon EC2 Container Service Discovery"
        author "Javieros Ros"
        start on stopped rc RUNLEVEL=[345]
        exec /usr/local/bin/ecssd_agent internal >> /var/log/ecssd_agent.log 2>&1
        respawn
