#cloud-config
manage_etc_hosts: True
runcmd:
  - export CONSUL_HOST=`ifconfig eth0 | grep "inet " | awk '{ print substr($2,6) }'`
  - sudo docker run -d --name=consul --restart unless-stopped --net=host consul:latest agent --server=true --ui=true --bind="$CONSUL_HOST" --client="$CONSUL_HOST" --node="consul-$CONSUL_HOST" --retry-join=${consul_hostname} --datacenter=${consul_datacenter} --bootstrap_expect=${consul_bootstrap_expect}
