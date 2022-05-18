#cloud-config
manage_etc_hosts: true
manage_resolv_conf: false
runcmd:
  - sudo bash -c 'echo "vm.max_map_count=1048575" >> /etc/sysctl.conf'
  - sudo bash -c 'echo "vm.swappiness=1" >> /etc/sysctl.conf'
  - sudo sysctl -w vm.max_map_count=1048575
  - sudo sysctl -w vm.swappiness=1
  - sudo hostname > /etc/hostname
  - sudo systemctl daemon-reload
  - sudo service docker restart
write_files:
  - path: /etc/profile.d/variables
    permissions: '0644'
    content: |
        ENVIRONMENT=${environment}
        COLOUR=${colour}
  - path: /etc/systemd/system/docker.service.d/simple_dockerd.conf
    permissions: '0644'
    content: |
        [Service]
        ExecStart=
        ExecStart=/usr/bin/dockerd
