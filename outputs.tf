output "api_base_url" {
  description = "Base URL for the API Gateway"
  value       = aws_api_gateway_stage.api_deployment.invoke_url
}

output "api_endpoints" {
  description = "Available API endpoints with methods"
  value = tomap({
    test = {
      path   = "/test"
      method = aws_api_gateway_method.test_method.http_method
    }
    fake = {
      path   = "/fake"
      method = aws_api_gateway_method.fake_method.http_method
    }
  })
}
