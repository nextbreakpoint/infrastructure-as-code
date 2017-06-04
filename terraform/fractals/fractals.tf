##############################################################################
# Provider
##############################################################################

provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
  shared_credentials_file = "${var.aws_shared_credentials_file}"
}

##############################################################################
# API Gateway
##############################################################################

resource "aws_api_gateway_rest_api" "FractalsAPI" {
  name = "FractalsAPI"
  binary_media_types = ["image/png", "application/octet-stream"]
}

resource "aws_api_gateway_resource" "FractalsResource" {
  rest_api_id = "${aws_api_gateway_rest_api.FractalsAPI.id}"
  parent_id   = "${aws_api_gateway_rest_api.FractalsAPI.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "GetTile" {
  rest_api_id   = "${aws_api_gateway_rest_api.FractalsAPI.id}"
  resource_id   = "${aws_api_gateway_resource.FractalsResource.id}"
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.FractalsAPI.id}"
  resource_id             = "${aws_api_gateway_resource.FractalsResource.id}"
  http_method             = "${aws_api_gateway_method.GetTile.http_method}"
  integration_http_method = "POST"
  type                    = "AWS"
  credentials             = "${aws_iam_role.apigw_role.arn}"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.lambda.arn}/invocations"
  passthrough_behavior    = "WHEN_NO_TEMPLATES"
  request_templates {
    "application/json" = <<EOF
#set($allParams = $input.params())
{
  "resource" : "$allParams.get('path').get('proxy')"
}
EOF
  }
}

resource "aws_api_gateway_method_response" "GetTileResponse200" {
  rest_api_id = "${aws_api_gateway_rest_api.FractalsAPI.id}"
  resource_id = "${aws_api_gateway_resource.FractalsResource.id}"
  http_method = "${aws_api_gateway_method.GetTile.http_method}"
  status_code = "200"
  response_parameters = { "method.response.header.Content-Type" = true }
  response_models = { "image/png" = "Empty" }
}

resource "aws_api_gateway_integration_response" "integration_response" {
  depends_on        = ["aws_api_gateway_integration.integration"] 
  rest_api_id       = "${aws_api_gateway_rest_api.FractalsAPI.id}"
  resource_id       = "${aws_api_gateway_resource.FractalsResource.id}"
  http_method       = "${aws_api_gateway_method.GetTile.http_method}"
  status_code       = "${aws_api_gateway_method_response.GetTileResponse200.status_code}"
  #response_parameters = { "method.response.header.Content-Type" = "integration.response.header.Content-Type" }
  response_templates = { "image/png" = "", "application/octet-stream" = "" }
}

resource "aws_api_gateway_deployment" "deployment_v1" {
  depends_on    = ["aws_api_gateway_rest_api.FractalsAPI", "aws_lambda_function.lambda"]
  rest_api_id   = "${aws_api_gateway_rest_api.FractalsAPI.id}"
  stage_name    = "v1"
  variables     = {}
}

/*
resource "aws_api_gateway_stage" "v1" {
  stage_name = "v1"
  rest_api_id = "${aws_api_gateway_rest_api.FractalsAPI.id}"
  deployment_id = "${aws_api_gateway_deployment.deployment_v1.id}"
  cache_cluster_enabled = "true"
}
*/

##############################################################################
# Lambda
##############################################################################

resource "aws_lambda_permission" "lambda" {
  statement_id    = "AllowExecutionFromAPIGateway"
  action          = "lambda:InvokeFunction"
  function_name   = "${aws_lambda_function.lambda.function_name}"
  principal       = "apigateway.amazonaws.com"
  source_account  = "${var.aws_account_id}"
  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn      = "arn:aws:execute-api:${var.aws_region}:${var.aws_account_id}:${aws_api_gateway_rest_api.FractalsAPI.id}/*/${aws_api_gateway_method.GetTile.http_method}/*"
}

resource "aws_lambda_function" "lambda" {
  filename         = "com.nextbreakpoint.nextfractal.lambda-2.0.1-fat.jar"
  function_name    = "FractalsAPI"
  role             = "${aws_iam_role.lambda_role.arn}"
  handler          = "com.nextbreakpoint.nextfractal.lambda.FractalsHandler::handleRequest"
  runtime          = "java8"
  memory_size      = "512"
  timeout          = "30"
  source_code_hash = "${base64sha256(file("com.nextbreakpoint.nextfractal.lambda-2.0.1-fat.jar"))}"
}

##############################################################################
# IAM
##############################################################################

resource "aws_iam_role" "lambda_role" {
  name               = "FractalsLambda"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role" "apigw_role" {
  name               = "FractalsAPIGateway"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "lambda_role_policy" {
  name = "FractalsLambdaPolicy"
  role = "${aws_iam_role.lambda_role.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
          "Effect": "Allow",
          "Action": [
              "logs:CreateLogGroup",
              "logs:CreateLogStream",
              "logs:PutLogEvents"
          ],
          "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::fractals-archive/*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "apigw_role_policy" {
  name = "FractalsAPIGatewayPolicy"
  role = "${aws_iam_role.apigw_role.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "lambda:InvokeFunction"
            ],
            "Resource": [
                "${aws_lambda_function.lambda.arn}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

