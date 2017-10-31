#!/bin/sh

echo '[extended]\nextendedKeyUsage=serverAuth,clientAuth' > openssl.cnf

openssl req -newkey rsa:2048 -days 365 -x509 -nodes -out /output/consul_ca_cert.pem -keyout /output/consul_ca_key.pem -passin pass:secret -passout pass:secret -subj "/CN=myself/OU=/O=/L=/ST=/C=/"

openssl req -newkey rsa:1024 -nodes -out /output/consul_server_cert.csr -keyout /output/consul_server_key.pem -passin pass:secret -passout pass:secret -subj "/CN=server.terraform.consul/OU=/O=/L=/ST=/C=/"

openssl x509 -req -extfile openssl.cnf -extensions extended -days 365 -CAcreateserial -CA /output/consul_ca_cert.pem -CAkey /output/consul_ca_key.pem -in /output/consul_server_cert.csr -out /output/consul_server_cert.pem -passin pass:secret
