variable "cluster_name" {
  type        = string
  description = "Name of the Minikube profile"
}

variable "driver" {
  type        = string
  default     = "docker"
  description = "Minikube virtualization driver"

  validation {
    condition     = contains(["docker", "none"], var.driver)
    error_message = "driver must be 'docker' or 'none'."
  }
}

variable "cpus" {
  type        = number
  description = "Number of CPUs to allocate"
}

variable "memory" {
  type        = number
  description = "Requested memory in MB (Terraform will auto-adjust)"
  validation {
    condition     = var.memory >= 512
    error_message = "memory must be >= 512 MB."
  }
}

variable "kubernetes_version" {
  type        = string
  default     = ""
  description = "Leave empty to auto-detect supported Kubernetes version"

  validation {
    condition     = var.kubernetes_version == "" || can(regex("^v1\\.[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "kubernetes_version must be empty or match format v1.X.Y"
  }
}
