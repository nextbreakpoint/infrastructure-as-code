#cloud-config
manage_etc_hosts: true
manage_resolv_conf: false
runcmd:
  - sudo modprobe ip_vs
  - sudo usermod -aG docker ubuntu
  - sudo sysctl net.bridge.bridge-nf-call-iptables=1
  - echo "source <(kubectl completion bash)" >> ~/.bashrc
  - export HOST_IP_ADDRESS=`ifconfig eth0 | grep "inet " | awk '{ print substr($2,6) }'`
  - sudo mkdir -p /etc/cni/net.d/
  - sudo wget -O /etc/cni/net.d/10-kuberouter.conf https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/cni/10-kuberouter.conf
  - bash -c "sleep 30"
  - sudo kubeadm join --token ${kubernetes_token} --skip-preflight-checks ${kubernetes_master_ip}:${kubernetes_master_port}
write_files:
  - path: /etc/profile.d/variables
    permissions: '0644'
    content: |
        ENVIRONMENT=${environment}
