#cloud-config
manage_etc_hosts: True
runcmd:
  - sudo modprobe ip_vs
  - sudo sysctl net.bridge.bridge-nf-call-iptables=1
  - echo "source <(kubectl completion bash)" >> ~/.bashrc
  - sudo mkdir -p /consul/config
  - sudo chmod -R ubuntu.ubuntu /consul
  - export HOST_IP_ADDRESS=`ifconfig eth0 | grep "inet " | awk '{ print substr($2,6) }'`
  - sudo -u ubuntu docker run -d --name=consul --restart unless-stopped --net=host -v /consul/config:/consul/config consul:latest agent -bind=$HOST_IP_ADDRESS -client=$HOST_IP_ADDRESS -node=kubernetes-$HOST_IP_ADDRESS -retry-join=${consul_hostname} -datacenter=${consul_datacenter}
  - sudo mkdir -p /etc/cni/net.d/
  - sudo wget -O /etc/cni/net.d/10-kuberouter.conf https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/cni/10-kuberouter.conf
  - sudo kubeadm join --token ${kubernetes_token} --skip-preflight-checks ${kubernetes_master_ip}:${kubernetes_master_port}
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
