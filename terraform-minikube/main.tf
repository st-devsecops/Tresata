terraform {
  required_version = ">= 1.3"
}

provider "local" {}
provider "null" {}

module "minikube" {
  source = "./modules/minikube"

  cluster_name       = "tf-minikube-${var.environment}"
  driver             = var.driver
  cpus               = var.cpus
  memory             = var.memory
  kubernetes_version = var.kubernetes_version
}
