variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

variable "aws_region" {
  type = string
}

variable "upload_bucket_arn" {
  type = string
}

variable "processed_bucket_arn" {
  type = string
}

variable "log_retention_days" {
  type    = number
  default = 7
}

variable "lambda_zip_path" {
  type = string
}

variable "handler" {
  type    = string
  default = "lambda_function.lambda_handler"
}

variable "source_code_hash" {
  type = string
}

variable "runtime" {
  type    = string
  default = "python3.12"
}

variable "timeout" {
  type    = number
  default = 60
}

variable "memory_size" {
  type    = number
  default = 1024
}

variable "lambda_layers" {
  type    = list(string)
  default = []
}

variable "processed_bucket_id" {
  type = string
}

variable "upload_bucket_id" {
  type = string
}

variable "log_level" {
  type    = string
  default = "INFO"
}

variable "environment_variables" {
  type    = map(string)
  default = {}
}