variable "environment" {
  type    = string
  default = "dev"
}

variable "driver" {
  type    = string
  default = "docker"
}

variable "cpus" {
  type    = number
  default = 2
}

variable "memory" {
  type    = number
  default = 4096
}

variable "kubernetes_version" {
  type    = string
  default = "v1.30.0"
}
