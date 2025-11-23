Note: The setup is tested on MAC

1. How to setup Minikube:
Go to terraform-minikube and run below.
terraform init
terraform plan -var-file=env/dev.tfvars
terraform apply -var-file=env/dev.tfvars

2. Deploy application and cross network policies
a. Create and push the image 
Go to election-api-image and run below
docker build -t election-api:latest .
minikube image load election-api:latest -p tf-minikube-dev
Go to election-app-chart and run below
helm install election-demo ./election-app-chart --create-namespace
once all the apps are up run below
on ns-b
kubectl exec -it voter-b -n ns-b -- wget -qO- --post-data="" http://election-api.ns-a.svc.cluster.local:80/vote/ironman
kubectl exec -it voter-b -n ns-b -- wget -qO- http://election-api.ns-a.svc.cluster.local:80/results
on ns-c
kubectl exec -it voter-c -n ns-c -- wget -qO- --post-data="" http://election-api.ns-a.svc.cluster.local:80/vote/hulk
on ns-a
kubectl exec -it voter-a-blocked -n ns-a -- wget -qO- --timeout=5 --post-data="" http://election-api.ns-a.svc.cluster.local:80/vote/captain

3. Install Trivy for vulnerebilities
Create one vul pod
kubectl run vulpod-1 --image=nginx:1.16.1 --restart=Never
helm repo add aqua https://aquasecurity.github.io/helm-charts/
helm repo update
helm install trivy-operator aqua/trivy-operator \
  -n trivy-system \
  --set trivy.ignoreUnfixed=true --create-namespace
kubectl get vulnerabilityreports -A
kubectl describe vulnerabilityreports pod-vulpod-1-vulpod-1

4. secrets as dont have vault setup on local
execute in secrets-roles 

5. Prometheus-Grafana
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring -- check 
kubectl get secret --namespace monitoring -l app.kubernetes.io/component=admin-secret -o jsonpath="{.items[0].data.admin-password}" | base64 --decode ; echo
just to check in prometheus data is coming 
* sum(rate(node_cpu_seconds_total{mode!="idle"}[5m])) by (instance)
* sum(rate(node_cpu_seconds_total{mode!="idle"}[5m])) by (instance)
To open grfana dashboard
minikube service prometheus-grafana -n monitoring -p tf-minikube-dev
kubectl get secret prometheus-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 --decode
Go to dashboard->datasource->new->prometheus->enter http://prometheus-kube-prometheus-prometheus.monitoring.svc:9090 --> svae&test

6. Elk install
Go to elk directory and install below
a. es-deployment-service.yaml
b. kibana-deployment-service.yaml
c. nginx-log-generator-deployment.yaml
d. filebeat-deployment.yaml


