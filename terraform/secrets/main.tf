##############################################################################
# Provider
##############################################################################

provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
  version = "~> 0.1"
}

provider "terraform" {
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
