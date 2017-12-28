##############################################################################
# Provider
##############################################################################

provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
  version = "~> 0.1"
}

##############################################################################
# S3 Bucket
##############################################################################

resource "aws_s3_bucket" "secrets" {
  bucket = "${var.secrets_bucket_name}"
  region = "${var.aws_region}"
  versioning = {
    enabled = true
  }
  acl = "private"
  force_destroy  = true

  tags {
    Stream = "${var.stream_tag}"
  }
}

##############################################################################
# S3 Bucket objects
##############################################################################

resource "aws_s3_bucket_object" "keystore-auth" {
  bucket = "${aws_s3_bucket.secrets.id}"
  key    = "environments/production/keystores/keystore-auth.jceks"
  source = "environments/production/keystores/keystore-auth.jceks"
  etag   = "${md5(file("environments/production/keystores/keystore-auth.jceks"))}"
}

resource "aws_s3_bucket_object" "keystore-client" {
  bucket = "${aws_s3_bucket.secrets.id}"
  key    = "environments/production/keystores/keystore-client.jks"
  source = "environments/production/keystores/keystore-client.jks"
  etag   = "${md5(file("environments/production/keystores/keystore-client.jks"))}"
}

resource "aws_s3_bucket_object" "keystore-server" {
  bucket = "${aws_s3_bucket.secrets.id}"
  key    = "environments/production/keystores/keystore-server.jks"
  source = "environments/production/keystores/keystore-server.jks"
  etag   = "${md5(file("environments/production/keystores/keystore-server.jks"))}"
}

resource "aws_s3_bucket_object" "truststore-client" {
  bucket = "${aws_s3_bucket.secrets.id}"
  key    = "environments/production/keystores/truststore-client.jks"
  source = "environments/production/keystores/truststore-client.jks"
  etag   = "${md5(file("environments/production/keystores/truststore-client.jks"))}"
}

resource "aws_s3_bucket_object" "truststore-server" {
  bucket = "${aws_s3_bucket.secrets.id}"
  key    = "environments/production/keystores/truststore-server.jks"
  source = "environments/production/keystores/truststore-server.jks"
  etag   = "${md5(file("environments/production/keystores/truststore-server.jks"))}"
}

resource "aws_s3_bucket_object" "nginx-certificate-with-ca-authority" {
  bucket = "${aws_s3_bucket.secrets.id}"
  key    = "environments/production/nginx/ca_and_server_cert.pem"
  source = "environments/production/nginx/ca_and_server_cert.pem"
  etag   = "${md5(file("environments/production/nginx/ca_and_server_cert.pem"))}"
}

resource "aws_s3_bucket_object" "nginx-certificate" {
  bucket = "${aws_s3_bucket.secrets.id}"
  key    = "environments/production/nginx/server_cert.pem"
  source = "environments/production/nginx/server_cert.pem"
  etag   = "${md5(file("environments/production/nginx/server_cert.pem"))}"
}

resource "aws_s3_bucket_object" "nginx-private-key" {
  bucket = "${aws_s3_bucket.secrets.id}"
  key    = "environments/production/nginx/server_key.pem"
  source = "environments/production/nginx/server_key.pem"
  etag   = "${md5(file("environments/production/nginx/server_key.pem"))}"
}

resource "aws_s3_bucket_object" "nginx-ca-certificate" {
  bucket = "${aws_s3_bucket.secrets.id}"
  key    = "environments/production/nginx/ca_cert.pem"
  source = "environments/production/nginx/ca_cert.pem"
  etag   = "${md5(file("environments/production/nginx/ca_cert.pem"))}"
}

resource "aws_s3_bucket_object" "consul-ca-certificate" {
  bucket = "${aws_s3_bucket.secrets.id}"
  key    = "environments/production/consul/ca_cert.pem"
  source = "environments/production/consul/ca_cert.pem"
  etag   = "${md5(file("environments/production/consul/ca_cert.pem"))}"
}

resource "aws_s3_bucket_object" "consul-certificate" {
  bucket = "${aws_s3_bucket.secrets.id}"
  key    = "environments/production/consul/server_cert.pem"
  source = "environments/production/consul/server_cert.pem"
  etag   = "${md5(file("environments/production/consul/server_cert.pem"))}"
}

resource "aws_s3_bucket_object" "consul-private-key" {
  bucket = "${aws_s3_bucket.secrets.id}"
  key    = "environments/production/consul/server_key.pem"
  source = "environments/production/consul/server_key.pem"
  etag   = "${md5(file("environments/production/consul/server_key.pem"))}"
}

resource "aws_s3_bucket_object" "filebeat-ca-certificate" {
  bucket = "${aws_s3_bucket.secrets.id}"
  key    = "environments/production/filebeat/ca_cert.pem"
  source = "environments/production/filebeat/ca_cert.pem"
  etag   = "${md5(file("environments/production/filebeat/ca_cert.pem"))}"
}

resource "aws_s3_bucket_object" "filebeat-certificate" {
  bucket = "${aws_s3_bucket.secrets.id}"
  key    = "environments/production/filebeat/filebeat_cert.pem"
  source = "environments/production/filebeat/filebeat_cert.pem"
  etag   = "${md5(file("environments/production/filebeat/filebeat_cert.pem"))}"
}

resource "aws_s3_bucket_object" "filebeat-private-key" {
  bucket = "${aws_s3_bucket.secrets.id}"
  key    = "environments/production/filebeat/filebeat_key.pem"
  source = "environments/production/filebeat/filebeat_key.pem"
  etag   = "${md5(file("environments/production/filebeat/filebeat_key.pem"))}"
}

resource "aws_s3_bucket_object" "filebeat-private-key-k8" {
  bucket = "${aws_s3_bucket.secrets.id}"
  key    = "environments/production/filebeat/filebeat_key.pkcs8"
  source = "environments/production/filebeat/filebeat_key.pkcs8"
  etag   = "${md5(file("environments/production/filebeat/filebeat_key.pkcs8"))}"
}

resource "aws_s3_bucket_object" "kibana-ca-certificate" {
  bucket = "${aws_s3_bucket.secrets.id}"
  key    = "environments/production/kibana/ca_cert.pem"
  source = "environments/production/kibana/ca_cert.pem"
  etag   = "${md5(file("environments/production/kibana/ca_cert.pem"))}"
}

resource "aws_s3_bucket_object" "kibana-certificate" {
  bucket = "${aws_s3_bucket.secrets.id}"
  key    = "environments/production/kibana/kibana_cert.pem"
  source = "environments/production/kibana/kibana_cert.pem"
  etag   = "${md5(file("environments/production/kibana/kibana_cert.pem"))}"
}

resource "aws_s3_bucket_object" "kibana-private-key" {
  bucket = "${aws_s3_bucket.secrets.id}"
  key    = "environments/production/kibana/kibana_key.pem"
  source = "environments/production/kibana/kibana_key.pem"
  etag   = "${md5(file("environments/production/kibana/kibana_key.pem"))}"
}

resource "aws_s3_bucket_object" "kibana-private-key-k8" {
  bucket = "${aws_s3_bucket.secrets.id}"
  key    = "environments/production/kibana/kibana_key.pkcs8"
  source = "environments/production/kibana/kibana_key.pkcs8"
  etag   = "${md5(file("environments/production/kibana/kibana_key.pkcs8"))}"
}

resource "aws_s3_bucket_object" "logstash-ca-certificate" {
  bucket = "${aws_s3_bucket.secrets.id}"
  key    = "environments/production/logstash/ca_cert.pem"
  source = "environments/production/logstash/ca_cert.pem"
  etag   = "${md5(file("environments/production/logstash/ca_cert.pem"))}"
}

resource "aws_s3_bucket_object" "logstash-certificate" {
  bucket = "${aws_s3_bucket.secrets.id}"
  key    = "environments/production/logstash/logstash_cert.pem"
  source = "environments/production/logstash/logstash_cert.pem"
  etag   = "${md5(file("environments/production/logstash/logstash_cert.pem"))}"
}

resource "aws_s3_bucket_object" "logstash-private-key" {
  bucket = "${aws_s3_bucket.secrets.id}"
  key    = "environments/production/logstash/logstash_key.pem"
  source = "environments/production/logstash/logstash_key.pem"
  etag   = "${md5(file("environments/production/logstash/logstash_key.pem"))}"
}

resource "aws_s3_bucket_object" "logstash-private-key-k8" {
  bucket = "${aws_s3_bucket.secrets.id}"
  key    = "environments/production/logstash/logstash_key.pkcs8"
  source = "environments/production/logstash/logstash_key.pkcs8"
  etag   = "${md5(file("environments/production/logstash/logstash_key.pkcs8"))}"
}

resource "aws_s3_bucket_object" "elasticsearch-ca-certificate" {
  bucket = "${aws_s3_bucket.secrets.id}"
  key    = "environments/production/elasticsearch/ca_cert.pem"
  source = "environments/production/elasticsearch/ca_cert.pem"
  etag   = "${md5(file("environments/production/elasticsearch/ca_cert.pem"))}"
}

resource "aws_s3_bucket_object" "elasticsearch-certificate" {
  bucket = "${aws_s3_bucket.secrets.id}"
  key    = "environments/production/elasticsearch/elasticsearch_cert.pem"
  source = "environments/production/elasticsearch/elasticsearch_cert.pem"
  etag   = "${md5(file("environments/production/elasticsearch/elasticsearch_cert.pem"))}"
}

resource "aws_s3_bucket_object" "elasticsearch-private-key" {
  bucket = "${aws_s3_bucket.secrets.id}"
  key    = "environments/production/elasticsearch/elasticsearch_key.pem"
  source = "environments/production/elasticsearch/elasticsearch_key.pem"
  etag   = "${md5(file("environments/production/elasticsearch/elasticsearch_key.pem"))}"
}

resource "aws_s3_bucket_object" "elasticsearch-private-key-k8" {
  bucket = "${aws_s3_bucket.secrets.id}"
  key    = "environments/production/elasticsearch/elasticsearch_key.pkcs8"
  source = "environments/production/elasticsearch/elasticsearch_key.pkcs8"
  etag   = "${md5(file("environments/production/elasticsearch/elasticsearch_key.pkcs8"))}"
}

resource "aws_s3_bucket_object" "jenkins-keystore" {
  bucket = "${aws_s3_bucket.secrets.id}"
  key    = "environments/production/jenkins/keystore.jks"
  source = "environments/production/jenkins/keystore.jks"
  etag   = "${md5(file("environments/production/jenkins/keystore.jks"))}"
}
