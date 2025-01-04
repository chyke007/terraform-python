variable "aws_region" {
  description = "AWS Region"
  default     = "us-east-1"
  type = string
}

variable "api_name" {
  description = "API Gateway"
  default     = "Lambda API"
}
