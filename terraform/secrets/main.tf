##############################################################################
# Providers
##############################################################################

provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
  version = "~> 0.1"
}

##############################################################################
# Resources
##############################################################################

# resource "aws_s3_bucket" "secrets" {
#   bucket        = "${var.secrets_bucket_name}"
#   region        = "${var.aws_region}"
#   acl           = "private"
#   force_destroy = true
#
#   tags {
#     Environment = "${var.environment}"
#     Colour      = "${var.colour}"
#   }
# }

resource "aws_s3_bucket_object" "keystore-client" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/keystores/keystore-client.jks"
  source = "../../secrets/environments/${var.environment}/${var.colour}/keystores/keystore-client.jks"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/keystores/keystore-client.jks"))}"
}

resource "aws_s3_bucket_object" "keystore-server" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/keystores/keystore-server.jks"
  source = "../../secrets/environments/${var.environment}/${var.colour}/keystores/keystore-server.jks"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/keystores/keystore-server.jks"))}"
}

resource "aws_s3_bucket_object" "truststore-client" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/keystores/truststore-client.jks"
  source = "../../secrets/environments/${var.environment}/${var.colour}/keystores/truststore-client.jks"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/keystores/truststore-client.jks"))}"
}

resource "aws_s3_bucket_object" "truststore-server" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/keystores/truststore-server.jks"
  source = "../../secrets/environments/${var.environment}/${var.colour}/keystores/truststore-server.jks"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/keystores/truststore-server.jks"))}"
}

resource "aws_s3_bucket_object" "nginx-certificate-with-ca-authority" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/nginx/ca_and_server_cert.pem"
  source = "../../secrets/environments/${var.environment}/${var.colour}/nginx/ca_and_server_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/nginx/ca_and_server_cert.pem"))}"
}

resource "aws_s3_bucket_object" "nginx-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/nginx/server_cert.pem"
  source = "../../secrets/environments/${var.environment}/${var.colour}/nginx/server_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/nginx/server_cert.pem"))}"
}

resource "aws_s3_bucket_object" "nginx-private-key" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/nginx/server_key.pem"
  source = "../../secrets/environments/${var.environment}/${var.colour}/nginx/server_key.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/nginx/server_key.pem"))}"
}

resource "aws_s3_bucket_object" "nginx-ca-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/nginx/ca_cert.pem"
  source = "../../secrets/environments/${var.environment}/${var.colour}/nginx/ca_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/nginx/ca_cert.pem"))}"
}

resource "aws_s3_bucket_object" "consul-ca-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/consul/ca_cert.pem"
  source = "../../secrets/environments/${var.environment}/${var.colour}/consul/ca_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/consul/ca_cert.pem"))}"
}

resource "aws_s3_bucket_object" "consul-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/consul/server_cert.pem"
  source = "../../secrets/environments/${var.environment}/${var.colour}/consul/server_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/consul/server_cert.pem"))}"
}

resource "aws_s3_bucket_object" "consul-private-key" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/consul/server_key.pem"
  source = "../../secrets/environments/${var.environment}/${var.colour}/consul/server_key.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/consul/server_key.pem"))}"
}

resource "aws_s3_bucket_object" "filebeat-ca-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/filebeat/ca_cert.pem"
  source = "../../secrets/environments/${var.environment}/${var.colour}/filebeat/ca_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/filebeat/ca_cert.pem"))}"
}

resource "aws_s3_bucket_object" "filebeat-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/filebeat/filebeat_cert.pem"
  source = "../../secrets/environments/${var.environment}/${var.colour}/filebeat/filebeat_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/filebeat/filebeat_cert.pem"))}"
}

resource "aws_s3_bucket_object" "filebeat-private-key" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/filebeat/filebeat_key.pem"
  source = "../../secrets/environments/${var.environment}/${var.colour}/filebeat/filebeat_key.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/filebeat/filebeat_key.pem"))}"
}

resource "aws_s3_bucket_object" "filebeat-private-key-k8" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/filebeat/filebeat_key.pkcs8"
  source = "../../secrets/environments/${var.environment}/${var.colour}/filebeat/filebeat_key.pkcs8"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/filebeat/filebeat_key.pkcs8"))}"
}

resource "aws_s3_bucket_object" "kibana-ca-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/kibana/ca_cert.pem"
  source = "../../secrets/environments/${var.environment}/${var.colour}/kibana/ca_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/kibana/ca_cert.pem"))}"
}

resource "aws_s3_bucket_object" "kibana-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/kibana/kibana_cert.pem"
  source = "../../secrets/environments/${var.environment}/${var.colour}/kibana/kibana_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/kibana/kibana_cert.pem"))}"
}

resource "aws_s3_bucket_object" "kibana-private-key" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/kibana/kibana_key.pem"
  source = "../../secrets/environments/${var.environment}/${var.colour}/kibana/kibana_key.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/kibana/kibana_key.pem"))}"
}

resource "aws_s3_bucket_object" "kibana-private-key-k8" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/kibana/kibana_key.pkcs8"
  source = "../../secrets/environments/${var.environment}/${var.colour}/kibana/kibana_key.pkcs8"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/kibana/kibana_key.pkcs8"))}"
}

resource "aws_s3_bucket_object" "logstash-ca-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/logstash/ca_cert.pem"
  source = "../../secrets/environments/${var.environment}/${var.colour}/logstash/ca_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/logstash/ca_cert.pem"))}"
}

resource "aws_s3_bucket_object" "logstash-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/logstash/logstash_cert.pem"
  source = "../../secrets/environments/${var.environment}/${var.colour}/logstash/logstash_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/logstash/logstash_cert.pem"))}"
}

resource "aws_s3_bucket_object" "logstash-private-key" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/logstash/logstash_key.pem"
  source = "../../secrets/environments/${var.environment}/${var.colour}/logstash/logstash_key.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/logstash/logstash_key.pem"))}"
}

resource "aws_s3_bucket_object" "logstash-private-key-k8" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/logstash/logstash_key.pkcs8"
  source = "../../secrets/environments/${var.environment}/${var.colour}/logstash/logstash_key.pkcs8"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/logstash/logstash_key.pkcs8"))}"
}

resource "aws_s3_bucket_object" "elasticsearch-ca-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/elasticsearch/ca_cert.pem"
  source = "../../secrets/environments/${var.environment}/${var.colour}/elasticsearch/ca_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/elasticsearch/ca_cert.pem"))}"
}

resource "aws_s3_bucket_object" "elasticsearch-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/elasticsearch/elasticsearch_cert.pem"
  source = "../../secrets/environments/${var.environment}/${var.colour}/elasticsearch/elasticsearch_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/elasticsearch/elasticsearch_cert.pem"))}"
}

resource "aws_s3_bucket_object" "elasticsearch-private-key" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/elasticsearch/elasticsearch_key.pem"
  source = "../../secrets/environments/${var.environment}/${var.colour}/elasticsearch/elasticsearch_key.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/elasticsearch/elasticsearch_key.pem"))}"
}

resource "aws_s3_bucket_object" "elasticsearch-private-key-k8" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/elasticsearch/elasticsearch_key.pkcs8"
  source = "../../secrets/environments/${var.environment}/${var.colour}/elasticsearch/elasticsearch_key.pkcs8"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/elasticsearch/elasticsearch_key.pkcs8"))}"
}

resource "aws_s3_bucket_object" "jenkins-keystore" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/jenkins/keystore.jks"
  source = "../../secrets/environments/${var.environment}/${var.colour}/jenkins/keystore.jks"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/jenkins/keystore.jks"))}"
}

resource "aws_s3_bucket_object" "openvpn-ca-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/openvpn/ca_cert.pem"
  source = "../../secrets/environments/${var.environment}/${var.colour}/openvpn/ca_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/openvpn/ca_cert.pem"))}"
}

resource "aws_s3_bucket_object" "openvpn-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/openvpn/server_cert.pem"
  source = "../../secrets/environments/${var.environment}/${var.colour}/openvpn/server_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/openvpn/server_cert.pem"))}"
}

resource "aws_s3_bucket_object" "openvpn-private-key" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/openvpn/server_key.pem"
  source = "../../secrets/environments/${var.environment}/${var.colour}/openvpn/server_key.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/openvpn/server_key.pem"))}"
}

resource "aws_s3_bucket_object" "openvpn-ta-auth" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/openvpn/ta.pem"
  source = "../../secrets/environments/${var.environment}/${var.colour}/openvpn/ta.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/openvpn/ta.pem"))}"
}

resource "aws_s3_bucket_object" "openvpn-dh-2048" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/openvpn/dh2048.pem"
  source = "../../secrets/environments/${var.environment}/${var.colour}/openvpn/dh2048.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/openvpn/dh2048.pem"))}"
}

resource "aws_s3_bucket_object" "swarm-server-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/swarm/server_cert.pem"
  source = "../../secrets/environments/${var.environment}/${var.colour}/swarm/server_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/swarm/server_cert.pem"))}"
}

resource "aws_s3_bucket_object" "swarm-server-private-key" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/swarm/server_key.pem"
  source = "../../secrets/environments/${var.environment}/${var.colour}/swarm/server_key.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/swarm/server_key.pem"))}"
}

resource "aws_s3_bucket_object" "swarm-client-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/swarm/client_cert.pem"
  source = "../../secrets/environments/${var.environment}/${var.colour}/swarm/client_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/swarm/client_cert.pem"))}"
}

resource "aws_s3_bucket_object" "swarm-client-private-key" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/swarm/client_key.pem"
  source = "../../secrets/environments/${var.environment}/${var.colour}/swarm/client_key.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/swarm/client_key.pem"))}"
}

resource "aws_s3_bucket_object" "swarm-ca-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/swarm/ca_cert.pem"
  source = "../../secrets/environments/${var.environment}/${var.colour}/swarm/ca_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/swarm/ca_cert.pem"))}"
}

resource "aws_s3_bucket_object" "kafka-keystore-server" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/kafka/keystore-server.jks"
  source = "../../secrets/environments/${var.environment}/${var.colour}/kafka/keystore-server.jks"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/kafka/keystore-server.jks"))}"
}

resource "aws_s3_bucket_object" "kafka-keystore-client" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/kafka/keystore-client.jks"
  source = "../../secrets/environments/${var.environment}/${var.colour}/kafka/keystore-client.jks"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/kafka/keystore-client.jks"))}"
}

resource "aws_s3_bucket_object" "kafka-truststore-server" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/kafka/truststore-server.jks"
  source = "../../secrets/environments/${var.environment}/${var.colour}/kafka/truststore-server.jks"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/kafka/truststore-server.jks"))}"
}

resource "aws_s3_bucket_object" "kafka-truststore-client" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/kafka/truststore-client.jks"
  source = "../../secrets/environments/${var.environment}/${var.colour}/kafka/truststore-client.jks"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/kafka/truststore-client.jks"))}"
}

resource "aws_s3_bucket_object" "kafka-password-keystore" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/kafka/password_keystore.txt"
  source = "../../secrets/environments/${var.environment}/${var.colour}/kafka/password_keystore.txt"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/kafka/password_keystore.txt"))}"
}

resource "aws_s3_bucket_object" "kafka-password-truststore" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/kafka/password_truststore.txt"
  source = "../../secrets/environments/${var.environment}/${var.colour}/kafka/password_truststore.txt"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/kafka/password_truststore.txt"))}"
}

resource "aws_s3_bucket_object" "kafka-client-jaas" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/kafka/client_jaas.conf"
  source = "../../secrets/environments/${var.environment}/${var.colour}/kafka/client_jaas.conf"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/kafka/client_jaas.conf"))}"
}

resource "aws_s3_bucket_object" "zookeeper-server-jaas" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/${var.colour}/zookeeper/server_jaas.conf"
  source = "../../secrets/environments/${var.environment}/${var.colour}/zookeeper/server_jaas.conf"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/${var.colour}/zookeeper/server_jaas.conf"))}"
}
