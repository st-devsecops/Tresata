###############################################################
# SYSTEM INFO (host RAM, Docker RAM, Minikube supported K8s)
###############################################################

data "external" "sysinfo" {
  program = ["bash", "-c", <<EOF
#!/bin/bash
set -e

# Detect host RAM in MB
HOST_RAM_MB=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024)}')

# Detect Docker Desktop memory (if running)
DOCKER_MEM=$(docker info --format '{{.MemTotal}}' 2>/dev/null | awk '{print int($1/1024/1024)}')
if [ -z "$DOCKER_MEM" ]; then
  DOCKER_MEM=$HOST_RAM_MB
fi

# Detect Minikube version
MK_VERSION=$(minikube version --short 2>/dev/null)

# Detect supported Kubernetes version
SUPPORTED_K8S=$(minikube config defaults kubernetes-version 2>/dev/null | awk '{print $NF}')

jq -n \
  --arg ram "$HOST_RAM_MB" \
  --arg dockermem "$DOCKER_MEM" \
  --arg mk "$MK_VERSION" \
  --arg k8s "$SUPPORTED_K8S" \
  '{"host_ram_mb":$ram, "docker_ram_mb":$dockermem, "minikube_version":$mk, "supported_k8s":$k8s}'
EOF
  ]
}

###############################################################
# LOCALS
###############################################################

locals {
  # RAM safety (Do not exceed Docker/Desktop RAM - 512 MB)
  safe_memory = (
    tonumber(data.external.sysinfo.result.docker_ram_mb) < var.memory ?
    tonumber(data.external.sysinfo.result.docker_ram_mb) - 512 :
    var.memory
  )

  # Kubernetes version (auto-detect if empty)
  k8s_version = (
    var.kubernetes_version != "" ?
    var.kubernetes_version :
    data.external.sysinfo.result.supported_k8s
  )
}

###############################################################
# START MINIKUBE
###############################################################

resource "null_resource" "start_minikube" {

  triggers = {
    cluster_name = var.cluster_name
    memory       = local.safe_memory
    k8s_version  = local.k8s_version
    cpus         = var.cpus
    always_run   = timestamp()
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOF
#!/bin/bash
set -e

PROFILE="${var.cluster_name}"

echo "---------------------------------------------------"
echo "Minikube Version         : ${data.external.sysinfo.result.minikube_version}"
echo "Supported K8s Version    : ${local.k8s_version}"
echo "Host RAM                 : ${data.external.sysinfo.result.host_ram_mb} MB"
echo "Docker Desktop Memory    : ${data.external.sysinfo.result.docker_ram_mb} MB"
echo "Using Safe Memory        : ${local.safe_memory} MB"
echo "---------------------------------------------------"

# Cleanup stale cache that causes coredns/coredns not found errors
echo "[INFO] Cleaning Minikube cache..."
minikube cache delete >/dev/null 2>&1 || true
rm -rf ~/.minikube/cache || true

if minikube status -p "$PROFILE" >/dev/null 2>&1; then
  echo "[INFO] Minikube '$PROFILE' already running — skipping start."
  exit 0
fi

echo "[INFO] Starting Minikube cluster: $PROFILE"

minikube start \
  -p "$PROFILE" \
  --driver=docker \
  --cpus=${var.cpus} \
  --memory=${local.safe_memory} \
  --image-repository=registry.k8s.io \
  --cache-images=false \
  --wait=all

# Enable storage-provisioner addon
echo "[INFO] Enabling storage-provisioner addon..."
minikube addons disable storage-provisioner -p "$PROFILE"

# Wait for nodes to be ready
echo "[INFO] Waiting for Kubernetes nodes to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=180s

echo "[SUCCESS] Minikube cluster '$PROFILE' is up!"
EOF
  }
}
