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

resource "aws_s3_bucket" "secrets" {
  bucket        = "${var.secrets_bucket_name}"
  region        = "${var.aws_region}"
  acl           = "private"
  force_destroy = true

  tags {
    Stream = "${var.stream_tag}"
  }
}

resource "aws_s3_bucket_object" "keystore-client" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/keystores/keystore-client.jks"
  source = "../../secrets/environments/${var.environment}/keystores/keystore-client.jks"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/keystores/keystore-client.jks"))}"
}

resource "aws_s3_bucket_object" "keystore-server" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/keystores/keystore-server.jks"
  source = "../../secrets/environments/${var.environment}/keystores/keystore-server.jks"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/keystores/keystore-server.jks"))}"
}

resource "aws_s3_bucket_object" "truststore-client" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/keystores/truststore-client.jks"
  source = "../../secrets/environments/${var.environment}/keystores/truststore-client.jks"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/keystores/truststore-client.jks"))}"
}

resource "aws_s3_bucket_object" "truststore-server" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/keystores/truststore-server.jks"
  source = "../../secrets/environments/${var.environment}/keystores/truststore-server.jks"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/keystores/truststore-server.jks"))}"
}

resource "aws_s3_bucket_object" "nginx-certificate-with-ca-authority" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/nginx/ca_and_server_cert.pem"
  source = "../../secrets/environments/${var.environment}/nginx/ca_and_server_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/nginx/ca_and_server_cert.pem"))}"
}

resource "aws_s3_bucket_object" "nginx-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/nginx/server_cert.pem"
  source = "../../secrets/environments/${var.environment}/nginx/server_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/nginx/server_cert.pem"))}"
}

resource "aws_s3_bucket_object" "nginx-private-key" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/nginx/server_key.pem"
  source = "../../secrets/environments/${var.environment}/nginx/server_key.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/nginx/server_key.pem"))}"
}

resource "aws_s3_bucket_object" "nginx-ca-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/nginx/ca_cert.pem"
  source = "../../secrets/environments/${var.environment}/nginx/ca_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/nginx/ca_cert.pem"))}"
}

resource "aws_s3_bucket_object" "consul-ca-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/consul/ca_cert.pem"
  source = "../../secrets/environments/${var.environment}/consul/ca_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/consul/ca_cert.pem"))}"
}

resource "aws_s3_bucket_object" "consul-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/consul/server_cert.pem"
  source = "../../secrets/environments/${var.environment}/consul/server_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/consul/server_cert.pem"))}"
}

resource "aws_s3_bucket_object" "consul-private-key" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/consul/server_key.pem"
  source = "../../secrets/environments/${var.environment}/consul/server_key.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/consul/server_key.pem"))}"
}

resource "aws_s3_bucket_object" "filebeat-ca-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/filebeat/ca_cert.pem"
  source = "../../secrets/environments/${var.environment}/filebeat/ca_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/filebeat/ca_cert.pem"))}"
}

resource "aws_s3_bucket_object" "filebeat-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/filebeat/filebeat_cert.pem"
  source = "../../secrets/environments/${var.environment}/filebeat/filebeat_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/filebeat/filebeat_cert.pem"))}"
}

resource "aws_s3_bucket_object" "filebeat-private-key" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/filebeat/filebeat_key.pem"
  source = "../../secrets/environments/${var.environment}/filebeat/filebeat_key.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/filebeat/filebeat_key.pem"))}"
}

resource "aws_s3_bucket_object" "filebeat-private-key-k8" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/filebeat/filebeat_key.pkcs8"
  source = "../../secrets/environments/${var.environment}/filebeat/filebeat_key.pkcs8"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/filebeat/filebeat_key.pkcs8"))}"
}

resource "aws_s3_bucket_object" "kibana-ca-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/kibana/ca_cert.pem"
  source = "../../secrets/environments/${var.environment}/kibana/ca_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/kibana/ca_cert.pem"))}"
}

resource "aws_s3_bucket_object" "kibana-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/kibana/kibana_cert.pem"
  source = "../../secrets/environments/${var.environment}/kibana/kibana_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/kibana/kibana_cert.pem"))}"
}

resource "aws_s3_bucket_object" "kibana-private-key" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/kibana/kibana_key.pem"
  source = "../../secrets/environments/${var.environment}/kibana/kibana_key.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/kibana/kibana_key.pem"))}"
}

resource "aws_s3_bucket_object" "kibana-private-key-k8" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/kibana/kibana_key.pkcs8"
  source = "../../secrets/environments/${var.environment}/kibana/kibana_key.pkcs8"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/kibana/kibana_key.pkcs8"))}"
}

resource "aws_s3_bucket_object" "logstash-ca-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/logstash/ca_cert.pem"
  source = "../../secrets/environments/${var.environment}/logstash/ca_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/logstash/ca_cert.pem"))}"
}

resource "aws_s3_bucket_object" "logstash-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/logstash/logstash_cert.pem"
  source = "../../secrets/environments/${var.environment}/logstash/logstash_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/logstash/logstash_cert.pem"))}"
}

resource "aws_s3_bucket_object" "logstash-private-key" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/logstash/logstash_key.pem"
  source = "../../secrets/environments/${var.environment}/logstash/logstash_key.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/logstash/logstash_key.pem"))}"
}

resource "aws_s3_bucket_object" "logstash-private-key-k8" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/logstash/logstash_key.pkcs8"
  source = "../../secrets/environments/${var.environment}/logstash/logstash_key.pkcs8"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/logstash/logstash_key.pkcs8"))}"
}

resource "aws_s3_bucket_object" "elasticsearch-ca-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/elasticsearch/ca_cert.pem"
  source = "../../secrets/environments/${var.environment}/elasticsearch/ca_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/elasticsearch/ca_cert.pem"))}"
}

resource "aws_s3_bucket_object" "elasticsearch-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/elasticsearch/elasticsearch_cert.pem"
  source = "../../secrets/environments/${var.environment}/elasticsearch/elasticsearch_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/elasticsearch/elasticsearch_cert.pem"))}"
}

resource "aws_s3_bucket_object" "elasticsearch-private-key" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/elasticsearch/elasticsearch_key.pem"
  source = "../../secrets/environments/${var.environment}/elasticsearch/elasticsearch_key.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/elasticsearch/elasticsearch_key.pem"))}"
}

resource "aws_s3_bucket_object" "elasticsearch-private-key-k8" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/elasticsearch/elasticsearch_key.pkcs8"
  source = "../../secrets/environments/${var.environment}/elasticsearch/elasticsearch_key.pkcs8"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/elasticsearch/elasticsearch_key.pkcs8"))}"
}

resource "aws_s3_bucket_object" "jenkins-keystore" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/jenkins/keystore.jks"
  source = "../../secrets/environments/${var.environment}/jenkins/keystore.jks"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/jenkins/keystore.jks"))}"
}

resource "aws_s3_bucket_object" "openvpn-ca-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/openvpn/ca_cert.pem"
  source = "../../secrets/environments/${var.environment}/openvpn/ca_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/openvpn/ca_cert.pem"))}"
}

resource "aws_s3_bucket_object" "openvpn-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/openvpn/server_cert.pem"
  source = "../../secrets/environments/${var.environment}/openvpn/server_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/openvpn/server_cert.pem"))}"
}

resource "aws_s3_bucket_object" "openvpn-private-key" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/openvpn/server_key.pem"
  source = "../../secrets/environments/${var.environment}/openvpn/server_key.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/openvpn/server_key.pem"))}"
}

resource "aws_s3_bucket_object" "openvpn-ta-auth" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/openvpn/ta.pem"
  source = "../../secrets/environments/${var.environment}/openvpn/ta.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/openvpn/ta.pem"))}"
}

resource "aws_s3_bucket_object" "openvpn-dh-2048" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/openvpn/dh2048.pem"
  source = "../../secrets/environments/${var.environment}/openvpn/dh2048.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/openvpn/dh2048.pem"))}"
}

resource "aws_s3_bucket_object" "swarm-server-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/swarm/server_cert.pem"
  source = "../../secrets/environments/${var.environment}/swarm/server_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/swarm/server_cert.pem"))}"
}

resource "aws_s3_bucket_object" "swarm-server-private-key" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/swarm/server_key.pem"
  source = "../../secrets/environments/${var.environment}/swarm/server_key.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/swarm/server_key.pem"))}"
}

resource "aws_s3_bucket_object" "swarm-client-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/swarm/client_cert.pem"
  source = "../../secrets/environments/${var.environment}/swarm/client_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/swarm/client_cert.pem"))}"
}

resource "aws_s3_bucket_object" "swarm-client-private-key" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/swarm/client_key.pem"
  source = "../../secrets/environments/${var.environment}/swarm/client_key.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/swarm/client_key.pem"))}"
}

resource "aws_s3_bucket_object" "swarm-ca-certificate" {
  bucket = "${var.secrets_bucket_name}"
  key    = "environments/${var.environment}/swarm/ca_cert.pem"
  source = "../../secrets/environments/${var.environment}/swarm/ca_cert.pem"
  etag   = "${md5(file("../../secrets/environments/${var.environment}/swarm/ca_cert.pem"))}"
}
