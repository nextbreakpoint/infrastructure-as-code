#!/bin/sh

echo '[extended]\nextendedKeyUsage=serverAuth,clientAuth' > openssl.cnf

openssl req -newkey rsa:2048 -days 365 -x509 -nodes -out /output/consul_ca.cer -keyout /output/consul_ca.pem -passin pass:secret -passout pass:secret -subj "/CN=myself/OU=/O=/L=/ST=/C=/"

openssl req -newkey rsa:1024 -nodes -out /output/consul_server.csr -keyout /output/consul_server.key -passin pass:secret -passout pass:secret -subj "/CN=server.terraform.consul/OU=/O=/L=/ST=/C=/"

openssl x509 -req -extfile openssl.cnf -extensions extended -days 365 -CAcreateserial -CA /output/consul_ca.cer -CAkey /output/consul_ca.pem -in /output/consul_server.csr -out /output/consul_server.pem -passin pass:secret
