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
  - sudo kubeadm init --token ${kubernetes_token} --pod-network-cidr="${pod_network_cidr}" --apiserver-advertise-address=HOST_IP_ADDRESS --skip-preflight-checks
  - sudo -u ubuntu mkdir -p /home/ubuntu/.kube
  - sudo cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
  - sudo chown -R ubuntu:ubuntu /home/ubuntu/.kube
  - bash -c "sleep 180"
  - sudo -u ubuntu kubectl apply -f https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/daemonset/kubeadm-kuberouter.yaml
  - sudo -u ubuntu kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
  - sudo -u ubuntu kubectl get pods --all-namespaces
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
