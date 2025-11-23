environment = "prod"

minikube = {
  driver     = "docker"
  cpus       = 4
  memory     = "6g"
  nodes      = 1
  addons     = ["metrics-server", "ingress"]
  extra_args = []
}
