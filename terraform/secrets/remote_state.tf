##############################################################################
# Remote state
##############################################################################

terraform {
  backend "s3" {
    bucket = "nextbreakpoint-terraform"
    region = "eu-west-1"
    key    = "secrets.tfstate"
  }
}
