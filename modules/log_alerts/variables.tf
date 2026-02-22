variable "log_group_name" {
  type = string
}

variable "metric_namespace" {
  type    = string
  default = "ImageProcessor/Lambda"
}

variable "function_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "log_alerts_topic_arn" {
  type = string
}