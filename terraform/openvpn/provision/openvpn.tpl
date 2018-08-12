#cloud-config
manage_etc_hosts: true
manage_resolv_conf: false
runcmd:
  - sudo aws s3 cp s3://${bucket_name}/environments/${environment}/${colour}/openvpn/ca_cert.pem /etc/openvpn/ca_cert.pem
  - sudo aws s3 cp s3://${bucket_name}/environments/${environment}/${colour}/openvpn/server_key.pem /etc/openvpn/server_key.pem
  - sudo aws s3 cp s3://${bucket_name}/environments/${environment}/${colour}/openvpn/server_cert.pem /etc/openvpn/server_cert.pem
  - sudo aws s3 cp s3://${bucket_name}/environments/${environment}/${colour}/openvpn/ta.pem /etc/openvpn/ta.pem
  - sudo aws s3 cp s3://${bucket_name}/environments/${environment}/${colour}/openvpn/dh2048.pem /etc/openvpn/dh2048.pem
  - export HOST_IP_ADDRESS=`ifconfig eth0 | grep "inet " | awk '{ print substr($2,6) }'`
  - sudo sed -i "10i \*nat\n:POSTROUTING ACCEPT \[0:0\]\n-A POSTROUTING -s ${openvpn_cidr} -o eth0 -j MASQUERADE\nCOMMIT" /etc/ufw/before.rules
  - sudo sed -i 's/DEFAULT_FORWARD_POLICY=\"DROP\"/DEFAULT_FORWARD_POLICY=\"ACCEPT\"/g' /etc/default/ufw
  - sudo systemctl start openvpn@server
  - sudo systemctl enable openvpn@server
  - sudo ip addr show tun0
  - sudo ufw disable
  - sudo ufw allow 22
  - sudo ufw allow 53
  - sudo ufw allow 1194/udp
  - sudo ufw enable
  - sudo sysctl -p
  - sudo sh /update-route53-A.sh
bootcmd:
  - sudo bash -c "if [ -f '/update-route53-A.sh' ]; then sudo sh /update-route53-A.sh; fi"
write_files:
  - path: /etc/profile.d/variables
    permissions: '0644'
    content: |
        ENVIRONMENT=${environment}
        COLOUR=${colour}
  - path: /etc/sysctl.conf
    permissions: '0644'
    content: |
        net.ipv4.ip_forward=1
  - path: /update-route53-A.sh
    permissions: '0644'
    content: |
        #!/bin/sh

        if [ -z "$1" ]; then
            echo "IP not given...trying EC2 metadata...";
            IP=$( curl http://169.254.169.254/latest/meta-data/public-ipv4 )
        else
            IP="$1"
        fi
        echo "IP to update: $IP"

        HOSTED_ZONE_ID=${hosted_zone_id}
        echo "Hosted zone being modified: $HOSTED_ZONE_ID"

        INPUT_JSON=$( cat /update-route53-A.json | sed "s/127\.0\.0\.1/$IP/" )

        # http://docs.aws.amazon.com/cli/latest/reference/route53/change-resource-record-sets.html
        # We want to use the string variable command so put the file contents (batch-changes file) in the following JSON
        INPUT_JSON="{ \"ChangeBatch\": $INPUT_JSON }"

        aws route53 change-resource-record-sets --hosted-zone-id "$HOSTED_ZONE_ID" --cli-input-json "$INPUT_JSON"
  - path: /update-route53-A.json
    permissions: '0644'
    content: |
        {
          "Comment": "Update the A record set",
          "Changes": [
            {
              "Action": "UPSERT",
              "ResourceRecordSet": {
                "Name": "${openvpn_dns}",
                "Type": "A",
                "TTL": 300,
                "ResourceRecords": [
                  {
                    "Value": "127.0.0.1"
                  }
                ]
              }
            }
          ]
        }
  - path: /etc/openvpn/server.conf
    permissions: '0644'
    content: |
        port 1194
        proto udp

        dev tun

        ca ca_cert.pem
        cert server_cert.pem
        key server_key.pem # This file should be kept secret

        # Diffie hellman parameters.
        # Generate your own with:
        #   openssl dhparam -out dh2048.pem 2048
        dh dh2048.pem

        server ${openvpn_subnet} 255.255.255.0

        topology subnet

        ifconfig-pool-persist ipp.txt

        push "route ${aws_openvpn_subnet} 255.255.0.0"
        push "route ${aws_network_subnet} 255.255.0.0"
        push "route ${aws_bastion_subnet} 255.255.0.0"

        push "redirect-gateway def1 bypass-dhcp"

        #push "dhcp-option DNS ${aws_network_dns}"
        push "dhcp-option DNS 8.8.8.8"
        push "dhcp-option DNS 8.8.4.4"

        keepalive 10 120

        # Generate with:
        #   openvpn --genkey --secret ta.key
        #
        # The server and each client must have
        # a copy of this key.
        # The second parameter should be '0'
        # on the server and '1' on the clients.
        tls-auth ta.pem 0 # This file is secret
        key-direction 0

        cipher AES-128-CBC

        auth SHA256

        comp-lzo

        max-clients 10

        persist-key
        persist-tun

        user nobody
        group nogroup

        status openvpn-status.log

        verb 3
