##############################################################################
# Cloud Watch
##############################################################################

resource "aws_cloudwatch_log_group" "network" {
  name = "network"

  tags {
    environment = "terraform"
  }
}

resource "aws_cloudwatch_log_stream" "network" {
  name = "network"
  log_group_name = "${aws_cloudwatch_log_group.network.name}"
}
