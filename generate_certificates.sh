#!/bin/bash
export DIR=secrets

rm -fR $DIR

mkdir -p $DIR

docker build -t generate-certificates docker/certificates/.
docker run --rm -t -v $(pwd)/$DIR:/output generate-certificates

export DST=terraform/secrets/environments/production/keystores

mkdir -p $DST

cp $DIR/keystore-auth.jceks $DST
cp $DIR/keystore-client.jks $DST
cp $DIR/keystore-server.jks $DST
cp $DIR/truststore-client.jks $DST
cp $DIR/truststore-server.jks $DST

### Copy certificates and keys

export DST=terraform/secrets/environments/production/nginx

mkdir -p $DST

cp $DIR/ca_cert.pem $DST
cp $DIR/server_cert.pem $DST
cp $DIR/server_key.pem $DST
cp $DIR/ca_and_server_cert.pem $DST

export DST=terraform/secrets/environments/production/filebeat

mkdir -p $DST

cp $DIR/ca_cert.pem $DST
cp $DIR/filebeat_cert.pem $DST
cp $DIR/filebeat_key.pem $DST
cp $DIR/filebeat_key.pkcs8 $DST

export DST=terraform/secrets/environments/production/logstash

mkdir -p $DST

cp $DIR/ca_cert.pem $DST
cp $DIR/logstash_cert.pem $DST
cp $DIR/logstash_key.pem $DST
cp $DIR/logstash_key.pkcs8 $DST

export DST=terraform/secrets/environments/production/elasticsearch

mkdir -p $DST

cp $DIR/ca_cert.pem $DST
cp $DIR/elasticsearch_cert.pem $DST
cp $DIR/elasticsearch_key.pem $DST
cp $DIR/elasticsearch_key.pkcs8 $DST

export DST=terraform/secrets/environments/production/consul

mkdir -p $DST

cp $DIR/ca_cert.pem $DST
cp $DIR/consul_cert.pem $DST/server_cert.pem
cp $DIR/consul_key.pem $DST/server_key.pem
