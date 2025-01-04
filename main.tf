provider "aws" {
  region = var.aws_region
}

provider "archive" {}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Archive for all Lambda code
data "archive_file" "src_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/src.zip"
}

# Lambda Function for /test
resource "aws_lambda_function" "get_test_function" {
  function_name = "get-test-function"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "get-test.lambda_handler"
  runtime       = "python3.9"
  filename      = data.archive_file.src_zip.output_path
  source_code_hash = data.archive_file.src_zip.output_base64sha256
}

# Lambda Function for /fake
resource "aws_lambda_function" "get_fake_function" {
  function_name = "get-fake-function"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "get-fake.lambda_handler"
  runtime       = "python3.9"
  filename      = data.archive_file.src_zip.output_path
  source_code_hash = data.archive_file.src_zip.output_base64sha256
}

# API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name        = var.api_name
  description = "API Gateway for Lambda Functions"
}

# Resource and Method for /test
resource "aws_api_gateway_resource" "test_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "test"
}

resource "aws_api_gateway_method" "test_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.test_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "test_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.test_resource.id
  http_method             = aws_api_gateway_method.test_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.get_test_function.invoke_arn
}

# Resource and Method for /fake
resource "aws_api_gateway_resource" "fake_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "fake"
}

resource "aws_api_gateway_method" "fake_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.fake_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "fake_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.fake_resource.id
  http_method             = aws_api_gateway_method.fake_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.get_fake_function.invoke_arn
}

# Lambda Permissions
resource "aws_lambda_permission" "test_permission" {
  statement_id  = "AllowAPIGatewayInvokeTest"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_test_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/GET/test"
}

resource "aws_lambda_permission" "fake_permission" {
  statement_id  = "AllowAPIGatewayInvokeFake"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_fake_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/GET/fake"
}

# API Deployment
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  depends_on  = [
    aws_api_gateway_integration.test_integration,
    aws_api_gateway_integration.fake_integration
  ]
}

resource "aws_api_gateway_stage" "api_deployment" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "dev"
}
