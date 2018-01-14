#!/bin/sh

OUTPUT=$ROOT/secrets

if [ ! -d "$OUTPUT" ]; then

  mkdir -p $OUTPUT

  echo '[extended]\nextendedKeyUsage=serverAuth,clientAuth\nkeyUsage=digitalSignature,keyAgreement' > $OUTPUT/openssl.cnf

  ## Create keystore for JWT authentication
  keytool -genseckey -keystore $OUTPUT/keystore-auth.jceks -storetype PKCS12 -storepass secret -keyalg HMacSHA256 -keysize 2048 -alias HS256 -keypass secret
  keytool -genseckey -keystore $OUTPUT/keystore-auth.jceks -storetype PKCS12 -storepass secret -keyalg HMacSHA384 -keysize 2048 -alias HS384 -keypass secret
  keytool -genseckey -keystore $OUTPUT/keystore-auth.jceks -storetype PKCS12 -storepass secret -keyalg HMacSHA512 -keysize 2048 -alias HS512 -keypass secret
  keytool -genkey -keystore $OUTPUT/keystore-auth.jceks -storetype PKCS12 -storepass secret -keyalg RSA -keysize 2048 -alias RS256 -keypass secret -sigalg SHA256withRSA -dname "CN=myself" -validity 365
  keytool -genkey -keystore $OUTPUT/keystore-auth.jceks -storetype PKCS12 -storepass secret -keyalg RSA -keysize 2048 -alias RS384 -keypass secret -sigalg SHA384withRSA -dname "CN=myself" -validity 365
  keytool -genkey -keystore $OUTPUT/keystore-auth.jceks -storetype PKCS12 -storepass secret -keyalg RSA -keysize 2048 -alias RS512 -keypass secret -sigalg SHA512withRSA -dname "CN=myself" -validity 365
  keytool -genkeypair -keystore $OUTPUT/keystore-auth.jceks -storetype PKCS12 -storepass secret -keyalg EC -keysize 256 -alias ES256 -keypass secret -sigalg SHA256withECDSA -dname "CN=myself" -validity 365
  keytool -genkeypair -keystore $OUTPUT/keystore-auth.jceks -storetype PKCS12 -storepass secret -keyalg EC -keysize 256 -alias ES384 -keypass secret -sigalg SHA384withECDSA -dname "CN=myself" -validity 365
  keytool -genkeypair -keystore $OUTPUT/keystore-auth.jceks -storetype PKCS12 -storepass secret -keyalg EC -keysize 256 -alias ES512 -keypass secret -sigalg SHA512withECDSA -dname "CN=myself" -validity 365

  ## Create certificate authority (CA)
  openssl req -new -x509 -keyout $OUTPUT/ca_key.pem -out $OUTPUT/ca_cert.pem -days 365 -passin pass:secret -passout pass:secret -subj "/CN=myself"

  ## Create client keystore
  keytool -noprompt -keystore $OUTPUT/keystore-client.jks -genkey -alias selfsigned -dname "CN=myself" -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 365 -storepass secret -keypass secret

  ## Create server keystore
  keytool -noprompt -keystore $OUTPUT/keystore-server.jks -genkey -alias selfsigned -dname "CN=myself" -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 365 -storepass secret -keypass secret

  ## Create filebeat keystore
  keytool -noprompt -keystore $OUTPUT/keystore-filebeat.jks -genkey -alias selfsigned -dname "CN=filebeat.service.terraform.consul" -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 365 -storepass secret -keypass secret

  ## Create logstash keystore
  keytool -noprompt -keystore $OUTPUT/keystore-kibana.jks -genkey -alias selfsigned -dname "CN=kibana.service.terraform.consul" -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 365 -storepass secret -keypass secret

  ## Create logstash keystore
  keytool -noprompt -keystore $OUTPUT/keystore-logstash.jks -genkey -alias selfsigned -dname "CN=logstash.service.terraform.consul" -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 365 -storepass secret -keypass secret

  ## Create elasticsearch keystore
  keytool -noprompt -keystore $OUTPUT/keystore-elasticsearch.jks -genkey -alias selfsigned -dname "CN=elasticsearch.service.terraform.consul" -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 365 -storepass secret -keypass secret

  ## Create jenkins keystore
  keytool -noprompt -keystore $OUTPUT/keystore-jenkins.jks -genkey -alias selfsigned -dname "CN=jenkins.service.terraform.consul" -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 365 -storepass secret -keypass secret

  ## Create consul keystore
  keytool -noprompt -keystore $OUTPUT/keystore-consul.jks -genkey -alias selfsigned -dname "CN=server.terraform.consul" -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 365 -storepass secret -keypass secret

  ## Create openvpn certificate authority (CA)
  openssl req -new -x509 -keyout $OUTPUT/openvpn_ca_key.pem -out $OUTPUT/openvpn_ca_cert.pem -days 365 -passin pass:secret -passout pass:secret -subj "/CN=openvpn"

  ## Create openvpn-server keystore
  keytool -noprompt -keystore $OUTPUT/keystore-openvpn-server.jks -genkey -alias selfsigned -dname "CN=openvpn" -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 365 -storepass secret -keypass secret

  ## Create openvpn-client keystore
  keytool -noprompt -keystore $OUTPUT/keystore-openvpn-client.jks -genkey -alias selfsigned -dname "CN=openvpn" -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 365 -storepass secret -keypass secret

  ## Sign client certificate
  keytool -noprompt -keystore $OUTPUT/keystore-client.jks -alias selfsigned -certreq -file $OUTPUT/client_csr.pem -storepass secret
  openssl x509 -extfile $OUTPUT/openssl.cnf -extensions extended -req -CA $OUTPUT/ca_cert.pem -CAkey $OUTPUT/ca_key.pem -in $OUTPUT/client_csr.pem -out $OUTPUT/client_cert.pem -days 365 -CAcreateserial -passin pass:secret

  ## Sign server certificate
  keytool -noprompt -keystore $OUTPUT/keystore-server.jks -alias selfsigned -certreq -file $OUTPUT/server_csr.pem -storepass secret
  openssl x509 -extfile $OUTPUT/openssl.cnf -extensions extended -req -CA $OUTPUT/ca_cert.pem -CAkey $OUTPUT/ca_key.pem -in $OUTPUT/server_csr.pem -out $OUTPUT/server_cert.pem -days 365 -CAcreateserial -passin pass:secret

  ## Sign filebeat certificate
  keytool -noprompt -keystore $OUTPUT/keystore-filebeat.jks -alias selfsigned -certreq -file $OUTPUT/filebeat_csr.pem -storepass secret
  openssl x509 -extfile $OUTPUT/openssl.cnf -extensions extended -req -CA $OUTPUT/ca_cert.pem -CAkey $OUTPUT/ca_key.pem -in $OUTPUT/filebeat_csr.pem -out $OUTPUT/filebeat_cert.pem -days 365 -CAcreateserial -passin pass:secret

  ## Sign kibana certificate
  keytool -noprompt -keystore $OUTPUT/keystore-kibana.jks -alias selfsigned -certreq -file $OUTPUT/kibana_csr.pem -storepass secret
  openssl x509 -extfile $OUTPUT/openssl.cnf -extensions extended -req -CA $OUTPUT/ca_cert.pem -CAkey $OUTPUT/ca_key.pem -in $OUTPUT/kibana_csr.pem -out $OUTPUT/kibana_cert.pem -days 365 -CAcreateserial -passin pass:secret

  ## Sign logstash certificate
  keytool -noprompt -keystore $OUTPUT/keystore-logstash.jks -alias selfsigned -certreq -file $OUTPUT/logstash_csr.pem -storepass secret
  openssl x509 -extfile $OUTPUT/openssl.cnf -extensions extended -req -CA $OUTPUT/ca_cert.pem -CAkey $OUTPUT/ca_key.pem -in $OUTPUT/logstash_csr.pem -out $OUTPUT/logstash_cert.pem -days 365 -CAcreateserial -passin pass:secret

  ## Sign elasticsearch certificate
  keytool -noprompt -keystore $OUTPUT/keystore-elasticsearch.jks -alias selfsigned -certreq -file $OUTPUT/elasticsearch_csr.pem -storepass secret
  openssl x509 -extfile $OUTPUT/openssl.cnf -extensions extended -req -CA $OUTPUT/ca_cert.pem -CAkey $OUTPUT/ca_key.pem -in $OUTPUT/elasticsearch_csr.pem -out $OUTPUT/elasticsearch_cert.pem -days 365 -CAcreateserial -passin pass:secret

  ## Sign consul certificate
  keytool -noprompt -keystore $OUTPUT/keystore-consul.jks -alias selfsigned -certreq -file $OUTPUT/consul_csr.pem -storepass secret
  openssl x509 -extfile $OUTPUT/openssl.cnf -extensions extended -req -CA $OUTPUT/ca_cert.pem -CAkey $OUTPUT/ca_key.pem -in $OUTPUT/consul_csr.pem -out $OUTPUT/consul_cert.pem -days 365 -CAcreateserial -passin pass:secret

  ## Sign openvpn-server certificate
  keytool -noprompt -keystore $OUTPUT/keystore-openvpn-server.jks -alias selfsigned -certreq -file $OUTPUT/openvpn_server_csr.pem -storepass secret
  openssl x509 -extfile $OUTPUT/openssl.cnf -extensions extended -req -CA $OUTPUT/openvpn_ca_cert.pem -CAkey $OUTPUT/openvpn_ca_key.pem -in $OUTPUT/openvpn_server_csr.pem -out $OUTPUT/openvpn_server_cert.pem -days 365 -CAcreateserial -passin pass:secret

  ## Sign openvpn-client certificate
  keytool -noprompt -keystore $OUTPUT/keystore-openvpn-client.jks -alias selfsigned -certreq -file $OUTPUT/openvpn_client_csr.pem -storepass secret
  openssl x509 -extfile $OUTPUT/openssl.cnf -extensions extended -req -CA $OUTPUT/openvpn_ca_cert.pem -CAkey $OUTPUT/openvpn_ca_key.pem -in $OUTPUT/openvpn_client_csr.pem -out $OUTPUT/openvpn_client_cert.pem -days 365 -CAcreateserial -passin pass:secret

  ## Import CA and client signed certificate into client keystore
  keytool -noprompt -keystore $OUTPUT/keystore-client.jks -alias CARoot -import -file $OUTPUT/ca_cert.pem -storepass secret
  keytool -noprompt -keystore $OUTPUT/keystore-client.jks -alias selfsigned -import -file $OUTPUT/client_cert.pem -storepass secret

  ## Import CA and server signed certificate into server keystore
  keytool -noprompt -keystore $OUTPUT/keystore-server.jks -alias CARoot -import -file $OUTPUT/ca_cert.pem -storepass secret
  keytool -noprompt -keystore $OUTPUT/keystore-server.jks -alias selfsigned -import -file $OUTPUT/server_cert.pem -storepass secret

  ## Import CA and filebeat signed certificate into filebeat keystore
  keytool -noprompt -keystore $OUTPUT/keystore-filebeat.jks -alias CARoot -import -file $OUTPUT/ca_cert.pem -storepass secret
  keytool -noprompt -keystore $OUTPUT/keystore-filebeat.jks -alias selfsigned -import -file $OUTPUT/filebeat_cert.pem -storepass secret

  ## Import CA and kibana signed certificate into kibana keystore
  keytool -noprompt -keystore $OUTPUT/keystore-kibana.jks -alias CARoot -import -file $OUTPUT/ca_cert.pem -storepass secret
  keytool -noprompt -keystore $OUTPUT/keystore-kibana.jks -alias selfsigned -import -file $OUTPUT/kibana_cert.pem -storepass secret

  ## Import CA and logstash signed certificate into logstash keystore
  keytool -noprompt -keystore $OUTPUT/keystore-logstash.jks -alias CARoot -import -file $OUTPUT/ca_cert.pem -storepass secret
  keytool -noprompt -keystore $OUTPUT/keystore-logstash.jks -alias selfsigned -import -file $OUTPUT/logstash_cert.pem -storepass secret

  ## Import CA and elasticsearch signed certificate into elasticsearch keystore
  keytool -noprompt -keystore $OUTPUT/keystore-elasticsearch.jks -alias CARoot -import -file $OUTPUT/ca_cert.pem -storepass secret
  keytool -noprompt -keystore $OUTPUT/keystore-elasticsearch.jks -alias selfsigned -import -file $OUTPUT/elasticsearch_cert.pem -storepass secret

  ## Import CA and consul signed certificate into consul keystore
  keytool -noprompt -keystore $OUTPUT/keystore-consul.jks -alias CARoot -import -file $OUTPUT/ca_cert.pem -storepass secret
  keytool -noprompt -keystore $OUTPUT/keystore-consul.jks -alias selfsigned -import -file $OUTPUT/consul_cert.pem -storepass secret

  ## Import CA and openvpn-server signed certificate into openvpn keystore
  keytool -noprompt -keystore $OUTPUT/keystore-openvpn-server.jks -alias CARoot -import -file $OUTPUT/openvpn_ca_cert.pem -storepass secret
  keytool -noprompt -keystore $OUTPUT/keystore-openvpn-server.jks -alias selfsigned -import -file $OUTPUT/openvpn_server_cert.pem -storepass secret

  ## Import CA and openvpn-client signed certificate into openvpn keystore
  keytool -noprompt -keystore $OUTPUT/keystore-openvpn-client.jks -alias CARoot -import -file $OUTPUT/openvpn_ca_cert.pem -storepass secret
  keytool -noprompt -keystore $OUTPUT/keystore-openvpn-client.jks -alias selfsigned -import -file $OUTPUT/openvpn_client_cert.pem -storepass secret

  ## Import CA into client truststore
  keytool -noprompt -keystore $OUTPUT/truststore-client.jks -alias CARoot -import -file $OUTPUT/ca_cert.pem -storepass secret

  ## Import CA into server truststore
  keytool -noprompt -keystore $OUTPUT/truststore-server.jks -alias CARoot -import -file $OUTPUT/ca_cert.pem -storepass secret

  ## Fetch Amazon CAs
  curl -o $OUTPUT/AmazonRootCA1.pem https://www.amazontrust.com/repository/AmazonRootCA1.pem
  curl -o $OUTPUT/AmazonRootCA2.pem https://www.amazontrust.com/repository/AmazonRootCA2.pem
  curl -o $OUTPUT/AmazonRootCA3.pem https://www.amazontrust.com/repository/AmazonRootCA3.pem
  curl -o $OUTPUT/AmazonRootCA4.pem https://www.amazontrust.com/repository/AmazonRootCA4.pem

  ## Import Amazon CAs into client truststore
  keytool -noprompt -keystore $OUTPUT/truststore-client.jks -alias AmazonRootCA1 -import -file $OUTPUT/AmazonRootCA1.pem -storepass secret
  keytool -noprompt -keystore $OUTPUT/truststore-client.jks -alias AmazonRootCA2 -import -file $OUTPUT/AmazonRootCA2.pem -storepass secret
  keytool -noprompt -keystore $OUTPUT/truststore-client.jks -alias AmazonRootCA3 -import -file $OUTPUT/AmazonRootCA3.pem -storepass secret
  keytool -noprompt -keystore $OUTPUT/truststore-client.jks -alias AmazonRootCA4 -import -file $OUTPUT/AmazonRootCA4.pem -storepass secret

  ## Import Amazon CAs into server truststore
  keytool -noprompt -keystore $OUTPUT/truststore-server.jks -alias AmazonRootCA1 -import -file $OUTPUT/AmazonRootCA1.pem -storepass secret
  keytool -noprompt -keystore $OUTPUT/truststore-server.jks -alias AmazonRootCA2 -import -file $OUTPUT/AmazonRootCA2.pem -storepass secret
  keytool -noprompt -keystore $OUTPUT/truststore-server.jks -alias AmazonRootCA3 -import -file $OUTPUT/AmazonRootCA3.pem -storepass secret
  keytool -noprompt -keystore $OUTPUT/truststore-server.jks -alias AmazonRootCA4 -import -file $OUTPUT/AmazonRootCA4.pem -storepass secret

  ## Create PEM files for NGINX, Logstash, Filebeat, Elasticsearch, Consul

  ### Extract signed client certificate
  keytool -noprompt -keystore $OUTPUT/keystore-client.jks -exportcert -alias selfsigned -rfc -storepass secret -file $OUTPUT/client_cert.pem

  ### Extract client key
  keytool -noprompt -srckeystore $OUTPUT/keystore-client.jks -importkeystore -srcalias selfsigned -destkeystore $OUTPUT/client_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass secret -storepass secret
  openssl pkcs12 -in $OUTPUT/client_cert_and_key.p12 -nocerts -nodes -passin pass:secret -out $OUTPUT/client_key.pem

  ### Extract signed server certificate
  keytool -noprompt -keystore $OUTPUT/keystore-server.jks -exportcert -alias selfsigned -rfc -storepass secret -file $OUTPUT/server_cert.pem

  ### Extract server key
  keytool -noprompt -srckeystore $OUTPUT/keystore-server.jks -importkeystore -srcalias selfsigned -destkeystore $OUTPUT/server_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass secret -storepass secret
  openssl pkcs12 -in $OUTPUT/server_cert_and_key.p12 -nocerts -nodes -passin pass:secret -out $OUTPUT/server_key.pem

  ### Extract signed filebeat certificate
  keytool -noprompt -keystore $OUTPUT/keystore-filebeat.jks -exportcert -alias selfsigned -rfc -storepass secret -file $OUTPUT/filebeat_cert.pem

  ### Extract filebeat key
  keytool -noprompt -srckeystore $OUTPUT/keystore-filebeat.jks -importkeystore -srcalias selfsigned -destkeystore $OUTPUT/filebeat_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass secret -storepass secret
  openssl pkcs12 -in $OUTPUT/filebeat_cert_and_key.p12 -nocerts -nodes -passin pass:secret -out $OUTPUT/filebeat_key.pem

  ### Extract signed kibana certificate
  keytool -noprompt -keystore $OUTPUT/keystore-kibana.jks -exportcert -alias selfsigned -rfc -storepass secret -file $OUTPUT/kibana_cert.pem

  ### Extract kibana key
  keytool -noprompt -srckeystore $OUTPUT/keystore-kibana.jks -importkeystore -srcalias selfsigned -destkeystore $OUTPUT/kibana_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass secret -storepass secret
  openssl pkcs12 -in $OUTPUT/kibana_cert_and_key.p12 -nocerts -nodes -passin pass:secret -out $OUTPUT/kibana_key.pem

  ### Extract signed logstash certificate
  keytool -noprompt -keystore $OUTPUT/keystore-logstash.jks -exportcert -alias selfsigned -rfc -storepass secret -file $OUTPUT/logstash_cert.pem

  ### Extract logstash key
  keytool -noprompt -srckeystore $OUTPUT/keystore-logstash.jks -importkeystore -srcalias selfsigned -destkeystore $OUTPUT/logstash_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass secret -storepass secret
  openssl pkcs12 -in $OUTPUT/logstash_cert_and_key.p12 -nocerts -nodes -passin pass:secret -out $OUTPUT/logstash_key.pem

  ### Extract signed elasticsearch certificate
  keytool -noprompt -keystore $OUTPUT/keystore-elasticsearch.jks -exportcert -alias selfsigned -rfc -storepass secret -file $OUTPUT/elasticsearch_cert.pem

  ### Extract elasticsearch key
  keytool -noprompt -srckeystore $OUTPUT/keystore-elasticsearch.jks -importkeystore -srcalias selfsigned -destkeystore $OUTPUT/elasticsearch_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass secret -storepass secret
  openssl pkcs12 -in $OUTPUT/elasticsearch_cert_and_key.p12 -nocerts -nodes -passin pass:secret -out $OUTPUT/elasticsearch_key.pem

  ### Extract signed consul certificate
  keytool -noprompt -keystore $OUTPUT/keystore-consul.jks -exportcert -alias selfsigned -rfc -storepass secret -file $OUTPUT/consul_cert.pem

  ### Extract consul key
  keytool -noprompt -srckeystore $OUTPUT/keystore-consul.jks -importkeystore -srcalias selfsigned -destkeystore $OUTPUT/consul_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass secret -storepass secret
  openssl pkcs12 -in $OUTPUT/consul_cert_and_key.p12 -nocerts -nodes -passin pass:secret -out $OUTPUT/consul_key.pem

  ### Extract signed openvpn-server certificate
  keytool -noprompt -keystore $OUTPUT/keystore-openvpn-server.jks -exportcert -alias selfsigned -rfc -storepass secret -file $OUTPUT/openvpn_server_cert.pem

  ### Extract openvpn-server key
  keytool -noprompt -srckeystore $OUTPUT/keystore-openvpn-server.jks -importkeystore -srcalias selfsigned -destkeystore $OUTPUT/openvpn_server_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass secret -storepass secret
  openssl pkcs12 -in $OUTPUT/openvpn_server_cert_and_key.p12 -nocerts -nodes -passin pass:secret -out $OUTPUT/openvpn_server_key.pem

  ### Extract signed openvpn-client certificate
  keytool -noprompt -keystore $OUTPUT/keystore-openvpn-client.jks -exportcert -alias selfsigned -rfc -storepass secret -file $OUTPUT/openvpn_client_cert.pem

  ### Extract openvpn-client key
  keytool -noprompt -srckeystore $OUTPUT/keystore-openvpn-client.jks -importkeystore -srcalias selfsigned -destkeystore $OUTPUT/openvpn_client_cert_and_key.p12 -deststoretype PKCS12 -srcstorepass secret -storepass secret
  openssl pkcs12 -in $OUTPUT/openvpn_client_cert_and_key.p12 -nocerts -nodes -passin pass:secret -out $OUTPUT/openvpn_client_key.pem

  ### Extract openvpn CA certificate
  keytool -noprompt -keystore $OUTPUT/keystore-openvpn-server.jks -exportcert -alias CARoot -rfc -storepass secret -file $OUTPUT/openvpn_ca_cert.pem

  ### Extract CA certificate
  keytool -noprompt -keystore $OUTPUT/keystore-server.jks -exportcert -alias CARoot -rfc -storepass secret -file $OUTPUT/ca_cert.pem

  ### Copy keystores and truststores

  cat $OUTPUT/client_cert.pem $OUTPUT/ca_cert.pem > $OUTPUT/ca_and_client_cert.pem
  cat $OUTPUT/server_cert.pem $OUTPUT/ca_cert.pem > $OUTPUT/ca_and_server_cert.pem

  openssl pkcs8 -in $OUTPUT/filebeat_key.pem -topk8 -inform PEM -nocrypt -out $OUTPUT/filebeat_key.pkcs8
  openssl pkcs8 -in $OUTPUT/kibana_key.pem -topk8 -inform PEM -nocrypt -out $OUTPUT/kibana_key.pkcs8
  openssl pkcs8 -in $OUTPUT/logstash_key.pem -topk8 -inform PEM -nocrypt -out $OUTPUT/logstash_key.pkcs8
  openssl pkcs8 -in $OUTPUT/elasticsearch_key.pem -topk8 -inform PEM -nocrypt -out $OUTPUT/elasticsearch_key.pkcs8

  openssl x509 -noout -text -in $OUTPUT/ca_cert.pem
  openssl x509 -noout -text -in $OUTPUT/consul_cert.pem
  openssl x509 -noout -text -in $OUTPUT/filebeat_cert.pem
  openssl x509 -noout -text -in $OUTPUT/kibana_cert.pem
  openssl x509 -noout -text -in $OUTPUT/logstash_cert.pem
  openssl x509 -noout -text -in $OUTPUT/elasticsearch_cert.pem

  openssl x509 -noout -text -in $OUTPUT/openvpn_ca_cert.pem
  openssl x509 -noout -text -in $OUTPUT/openvpn_server_cert.pem
  openssl x509 -noout -text -in $OUTPUT/openvpn_client_cert.pem

  openssl dhparam -out $OUTPUT/openvpn_dh2048.pem 2048
  openvpn --genkey --secret $OUTPUT/openvpn_ta.pem

else

  echo "Secrets folder already exists. Skipping!"

fi

DIR=$ROOT/secrets

DST=$ROOT/terraform/secrets/environments/production/keystores

mkdir -p $DST

cp $DIR/keystore-auth.jceks $DST
cp $DIR/keystore-client.jks $DST
cp $DIR/keystore-server.jks $DST
cp $DIR/truststore-client.jks $DST
cp $DIR/truststore-server.jks $DST

### Copy certificates and keys

DST=$ROOT/terraform/secrets/environments/production/nginx

mkdir -p $DST

cp $DIR/ca_cert.pem $DST
cp $DIR/server_cert.pem $DST
cp $DIR/server_key.pem $DST
cp $DIR/ca_and_server_cert.pem $DST

DST=$ROOT/terraform/secrets/environments/production/filebeat

mkdir -p $DST

cp $DIR/ca_cert.pem $DST
cp $DIR/filebeat_cert.pem $DST
cp $DIR/filebeat_key.pem $DST
cp $DIR/filebeat_key.pkcs8 $DST

DST=$ROOT/terraform/secrets/environments/production/kibana

mkdir -p $DST

cp $DIR/ca_cert.pem $DST
cp $DIR/kibana_cert.pem $DST
cp $DIR/kibana_key.pem $DST
cp $DIR/kibana_key.pkcs8 $DST

DST=$ROOT/terraform/secrets/environments/production/logstash

mkdir -p $DST

cp $DIR/ca_cert.pem $DST
cp $DIR/logstash_cert.pem $DST
cp $DIR/logstash_key.pem $DST
cp $DIR/logstash_key.pkcs8 $DST

DST=$ROOT/terraform/secrets/environments/production/elasticsearch

mkdir -p $DST

cp $DIR/ca_cert.pem $DST
cp $DIR/elasticsearch_cert.pem $DST
cp $DIR/elasticsearch_key.pem $DST
cp $DIR/elasticsearch_key.pkcs8 $DST

DST=$ROOT/terraform/secrets/environments/production/consul

mkdir -p $DST

cp $DIR/ca_cert.pem $DST
cp $DIR/consul_cert.pem $DST/server_cert.pem
cp $DIR/consul_key.pem $DST/server_key.pem

DST=$ROOT/terraform/secrets/environments/production/jenkins

mkdir -p $DST

cp $DIR/keystore-jenkins.jks $DST/keystore.jks

DST=$ROOT/terraform/secrets/environments/production/openvpn

mkdir -p $DST

cp $DIR/openvpn_ca_cert.pem $DST/ca_cert.pem
cp $DIR/openvpn_server_cert.pem $DST/server_cert.pem
cp $DIR/openvpn_server_key.pem $DST/server_key.pem
cp $DIR/openvpn_client_cert.pem $DST/client_cert.pem
cp $DIR/openvpn_client_key.pem $DST/client_key.pem
cp $DIR/openvpn_dh2048.pem $DST/dh2048.pem
cp $DIR/openvpn_ta.pem $DST/ta.pem
