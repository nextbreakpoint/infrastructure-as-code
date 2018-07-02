#cloud-config
manage_etc_hosts: true
manage_resolv_conf: false
runcmd:
  - sudo usermod -aG docker ubuntu
  - export HOST_IP_ADDRESS=`ifconfig eth0 | grep "inet " | awk '{ print substr($2,6) }'`
write_files:
  - path: /etc/profile.d/variables
    permissions: '0644'
    content: |
        ENVIRONMENT=${environment}
