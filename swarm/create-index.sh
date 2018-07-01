#!/bin/sh

curl -XPUT  --cacert ${SECRETS_PATH}/ca_cert.pem 'https://elastic:changeme@${ELASTICSEARCH_HOST}:9200/.kibana/index-pattern/filebeat-index.json' -H "Content-Type:application/json" -d@filebeat-index.json

#curl -XPOST --cacert ${SECRETS_PATH}/ca_cert.pem 'https://elastic:changeme@${ELASTICSEARCH_HOST}:9200/_xpack/security/user/logstash_system/_password?pretty' -H "Content-Type:application/json" -d@logstash.json
#curl -XPOST --cacert ${SECRETS_PATH}/ca_cert.pem 'https://elastic:changeme@${ELASTICSEARCH_HOST}:9200/_xpack/security/user/elastic/_password?pretty' -H "Content-Type:application/json" -d@/elasticsearch.json
#curl -XPOST --cacert ${SECRETS_PATH}/ca_cert.pem 'https://elastic:changeme@${ELASTICSEARCH_HOST}:9200/_xpack/security/user/kibana/_password?pretty' -H "Content-Type:application/json" -d@/kibana.json
