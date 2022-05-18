#cloud-config
manage_etc_hosts: true
manage_resolv_conf: false
runcmd:
  - sudo sh /etc/openvpn/secrets.sh
  - sudo sh /etc/openvpn/setup.sh
  - sh /update-route53-A.sh
bootcmd:
  - bash -c "if [ -f '/update-route53-A.sh' ]; then sh /update-route53-A.sh; fi"
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

        ca /etc/openvpn/ca_cert.pem
        cert /etc/openvpn/server_cert.pem
        key /etc/openvpn/server_key.pem # This file should be kept secret

        # Diffie hellman parameters.
        # Generate your own with:
        #   openssl dhparam -out dh2048.pem 2048
        dh /etc/openvpn/dh2048.pem

        server ${openvpn_subnet} 255.255.255.0

        topology subnet

        ifconfig-pool-persist ipp.txt

        push "route ${aws_platform_subnet} 255.255.0.0"
        push "route ${aws_openvpn_subnet} 255.255.0.0"
        push "route ${aws_bastion_subnet} 255.255.0.0"

        push "redirect-gateway def1 bypass-dhcp"

        #push "dhcp-option DNS ${aws_platform_dns}"
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
        tls-auth /etc/openvpn/ta_auth.pem 0 # This file is secret
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
  - path: /etc/openvpn/client.conf
    permissions: '0644'
    content: |
        client

        proto udp
        dev tun

        remote ${environment}-${colour}-openvpn.${hosted_zone_name} 1194

        resolv-retry infinite

        nobind

        persist-key
        persist-tun

        remote-cert-tls server

        key-direction 1

        cipher AES-128-CBC

        auth SHA256

        comp-lzo

        script-security 3

        verb 3

        explicit-exit-notify 1
  - path: /etc/openvpn/client.ovpn
    permissions: '0644'
    content: |
        client

        proto udp
        dev tun

        remote ${environment}-${colour}-openvpn.${hosted_zone_name} 1194

        resolv-retry infinite

        nobind

        persist-key
        persist-tun

        remote-cert-tls server

        key-direction 1

        cipher AES-128-CBC

        auth SHA256

        comp-lzo

        script-security 3

        verb 3

        explicit-exit-notify 1
  - path: /etc/openvpn/setup.sh
    permissions: '0644'
    content: |
        #!/bin/bash

        export HOST_IP_ADDRESS=`ip addr show dev eth0 | grep "inet " | awk '{ print $2 }'`

        sed -i "10i \*nat\n:POSTROUTING ACCEPT \[0:0\]\n-A POSTROUTING -s ${openvpn_cidr} -o eth0 -j MASQUERADE\nCOMMIT" /etc/ufw/before.rules
        sed -i 's/DEFAULT_FORWARD_POLICY=\"DROP\"/DEFAULT_FORWARD_POLICY=\"ACCEPT\"/g' /etc/default/ufw

        systemctl start openvpn@server
        systemctl enable openvpn@server

        ip addr show tun0

        ufw disable
        ufw allow 22
        ufw allow 53
        ufw allow 1194/udp
        ufw enable

        sysctl -p

        echo '<ca>' >> /etc/openvpn/client.ovpn
        cat /etc/openvpn/ca_cert.pem >> /etc/openvpn/client.ovpn
        echo '</ca>' >> /etc/openvpn/client.ovpn
        echo '<key>' >> /etc/openvpn/client.ovpn
        cat /etc/openvpn/client_key.pem >> /etc/openvpn/client.ovpn
        echo '</key>' >> /etc/openvpn/client.ovpn
        echo '<cert>' >> /etc/openvpn/client.ovpn
        cat /etc/openvpn/client_cert.pem >> /etc/openvpn/client.ovpn
        echo '</cert>' >> /etc/openvpn/client.ovpn
        echo '<tls-auth>' >> /etc/openvpn/client.ovpn
        cat /etc/openvpn/ta_auth.pem >> /etc/openvpn/client.ovpn
        echo '</tls-auth>' >> /etc/openvpn/client.ovpn

        aws s3 cp /etc/openvpn/client.ovpn s3://${bucket_name}/client.ovpn
        aws s3 cp /etc/openvpn/client.conf s3://${bucket_name}/client.conf
  - path: /etc/openvpn/secrets.sh
    permissions: '0644'
    content: |
        #!/bin/bash

        KEY_PASSWORD="${key_password}"
        KEYSTORE_PASSWORD="${keystore_password}"
        TRUSTSTORE_PASSWORD="${truststore_password}"
        HOSTED_ZONE_NAME="${hosted_zone_name}"

        SECRETS_PATH=/secrets

        mkdir -p $SECRETS_PATH

        ## Create openvpn certificate authority (CA)
        keytool -noprompt -keystore $SECRETS_PATH/openvpn_ca.jks -genkeypair -alias ca -dname "CN=openvpn" -ext KeyUsage=digitalSignature,keyCertSign -ext BasicConstraints=ca:true,PathLen:3 -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 365 -storepass $KEY_PASSWORD -keypass $KEY_PASSWORD
        openssl pkcs12 -in $SECRETS_PATH/openvpn_ca.jks -nocerts -nodes -passin pass:$KEY_PASSWORD -out $SECRETS_PATH/openvpn_ca_key.pem
        openssl pkcs12 -in $SECRETS_PATH/openvpn_ca.jks -nokeys -nodes -passin pass:$KEY_PASSWORD -out $SECRETS_PATH/openvpn_ca_cert.pem

        ## Create openvpn-server keystore
        keytool -noprompt -keystore $SECRETS_PATH/openvpn_server_keystore.jks -genkey -alias selfsigned -dname "CN=openvpn" -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 365 -storepass $KEYSTORE_PASSWORD -keypass $KEY_PASSWORD

        ## Create openvpn-client keystore
        keytool -noprompt -keystore $SECRETS_PATH/openvpn_client_keystore.jks -genkey -alias selfsigned -dname "CN=openvpn" -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 365 -storepass $KEYSTORE_PASSWORD -keypass $KEY_PASSWORD

        ## Sign openvpn-server certificate
        keytool -noprompt -keystore $SECRETS_PATH/openvpn_server_keystore.jks -alias selfsigned -certreq -file $SECRETS_PATH/openvpn_server_csr.pem -storepass $KEYSTORE_PASSWORD
        keytool -noprompt -keystore $SECRETS_PATH/openvpn_ca.jks -alias ca -gencert -infile $SECRETS_PATH/openvpn_server_csr.pem -outfile $SECRETS_PATH/openvpn_server_cert.pem -sigalg SHA256withRSA -ext KeyUsage=digitalSignature,keyAgreement -ext ExtendedKeyUsage=serverAuth,clientAuth -rfc -validity 365 -storepass $KEYSTORE_PASSWORD -keypass $KEY_PASSWORD

        ## Sign openvpn-client certificate
        keytool -noprompt -keystore $SECRETS_PATH/openvpn_client_keystore.jks -alias selfsigned -certreq -file $SECRETS_PATH/openvpn_client_csr.pem -storepass $KEYSTORE_PASSWORD
        keytool -noprompt -keystore $SECRETS_PATH/openvpn_ca.jks -alias ca -gencert -infile $SECRETS_PATH/openvpn_client_csr.pem -outfile $SECRETS_PATH/openvpn_client_cert.pem -sigalg SHA256withRSA -ext KeyUsage=digitalSignature,keyAgreement -ext ExtendedKeyUsage=serverAuth,clientAuth -rfc -validity 365 -storepass $KEYSTORE_PASSWORD -keypass $KEY_PASSWORD

        ## Import CA and openvpn-server signed certificate into openvpn keystore
        keytool -noprompt -keystore $SECRETS_PATH/openvpn_server_keystore.jks -alias CARoot -import -file $SECRETS_PATH/openvpn_ca_cert.pem -storepass $KEYSTORE_PASSWORD
        keytool -noprompt -keystore $SECRETS_PATH/openvpn_server_keystore.jks -alias selfsigned -import -file $SECRETS_PATH/openvpn_server_cert.pem -storepass $KEYSTORE_PASSWORD

        ## Import CA and openvpn-client signed certificate into openvpn keystore
        keytool -noprompt -keystore $SECRETS_PATH/openvpn_client_keystore.jks -alias CARoot -import -file $SECRETS_PATH/openvpn_ca_cert.pem -storepass $KEYSTORE_PASSWORD
        keytool -noprompt -keystore $SECRETS_PATH/openvpn_client_keystore.jks -alias selfsigned -import -file $SECRETS_PATH/openvpn_client_cert.pem -storepass $KEYSTORE_PASSWORD

        ### Extract signed openvpn-server certificate
        keytool -noprompt -keystore $SECRETS_PATH/openvpn_server_keystore.jks -exportcert -alias selfsigned -rfc -storepass $KEYSTORE_PASSWORD -file $SECRETS_PATH/openvpn_server_cert.pem

        ### Extract openvpn-server key
        keytool -noprompt -srckeystore $SECRETS_PATH/openvpn_server_keystore.jks -importkeystore -srcalias selfsigned -destkeystore $SECRETS_PATH/openvpn_server_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass $KEYSTORE_PASSWORD -storepass $KEYSTORE_PASSWORD
        openssl pkcs12 -in $SECRETS_PATH/openvpn_server_cert_and_key.p12 -nocerts -nodes -passin pass:$KEYSTORE_PASSWORD -out $SECRETS_PATH/openvpn_server_key.pem

        ### Extract signed openvpn-client certificate
        keytool -noprompt -keystore $SECRETS_PATH/openvpn_client_keystore.jks -exportcert -alias selfsigned -rfc -storepass $KEYSTORE_PASSWORD -file $SECRETS_PATH/openvpn_client_cert.pem

        ### Extract openvpn-client key
        keytool -noprompt -srckeystore $SECRETS_PATH/openvpn_client_keystore.jks -importkeystore -srcalias selfsigned -destkeystore $SECRETS_PATH/openvpn_client_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass $KEYSTORE_PASSWORD -storepass $KEYSTORE_PASSWORD
        openssl pkcs12 -in $SECRETS_PATH/openvpn_client_cert_and_key.p12 -nocerts -nodes -passin pass:$KEYSTORE_PASSWORD -out $SECRETS_PATH/openvpn_client_key.pem

        ### Extract openvpn CA certificate
        keytool -noprompt -keystore $SECRETS_PATH/openvpn_server_keystore.jks -exportcert -alias CARoot -rfc -storepass $KEYSTORE_PASSWORD -file $SECRETS_PATH/openvpn_ca_cert.pem

        openssl x509 -noout -text -in $SECRETS_PATH/openvpn_ca_cert.pem
        openssl x509 -noout -text -in $SECRETS_PATH/openvpn_server_cert.pem
        openssl x509 -noout -text -in $SECRETS_PATH/openvpn_client_cert.pem

        openssl dhparam -out $SECRETS_PATH/openvpn_dh2048.pem 2048
        openvpn --genkey secret $SECRETS_PATH/openvpn_ta_auth.pem

        ### Copy certificates and keys

        cp $SECRETS_PATH/openvpn_ca_cert.pem /etc/openvpn/ca_cert.pem
        cp $SECRETS_PATH/openvpn_server_cert.pem /etc/openvpn/server_cert.pem
        cp $SECRETS_PATH/openvpn_server_key.pem /etc/openvpn/server_key.pem
        cp $SECRETS_PATH/openvpn_client_cert.pem /etc/openvpn/client_cert.pem
        cp $SECRETS_PATH/openvpn_client_key.pem /etc/openvpn/client_key.pem
        cp $SECRETS_PATH/openvpn_dh2048.pem /etc/openvpn/dh2048.pem
        cp $SECRETS_PATH/openvpn_ta_auth.pem /etc/openvpn/ta_auth.pem
