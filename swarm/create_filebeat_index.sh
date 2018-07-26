#!/bin/sh

curl -XPUT  --cacert ${SECRETS_PATH}/ca_cert.pem 'https://elastic:changeme@${ELASTICSEARCH_HOST}:9200/.kibana/index-pattern/filebeat-index.json' -H "Content-Type:application/json" -d@filebeat-index.json
