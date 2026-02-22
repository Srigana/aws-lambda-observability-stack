variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "critical_alert_email" {
  type    = string
  default = ""
}

variable "performance_alert_email" {
  type    = string
  default = ""
}

variable "log_alert_email" {
  type    = string
  default = ""
}

