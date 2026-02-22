variable "upload_bucket_name" {
  type = string
}

variable "processed_bucket_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "environment" {
  type = string
}

variable "enable_versioning" {
  type    = bool
  default = true
}