variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "Existing EC2 key pair name for SSH"
  type        = string
}

variable "allowed_cidrs" {
  description = "CIDRs allowed to access Grafana/Prometheus/Alertmanager/SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "assets_bucket" {
  type = string
}

variable "assets_key" {
  type = string
}