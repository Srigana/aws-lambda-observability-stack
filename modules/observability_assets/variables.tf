variable "name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "zip_path" {
  description = "Path to observability.zip on local machine"
  type        = string
}
