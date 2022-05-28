#cloud-config
manage_etc_hosts: true
manage_resolv_conf: false
runcmd:
  - sudo apt install unzip
  - curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  - unzip awscliv2.zip
  - sudo ./aws/install
  - sh /update-route53-A.sh
bootcmd:
  - bash -c "if [ -f '/update-route53-A.sh' ]; then sh /update-route53-A.sh; fi"
write_files:
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
                "Name": "${bastion_dns}",
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
