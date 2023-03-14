# Install helm namespace
helm upgrade --cleanup-on-fail \
  --install cram jupyterhub/jupyterhub \
  --namespace cram\
  --create-namespace \
  --version=2.0.0 \
  --values config.yaml

# Upgrade helm namespace
helm upgrade --cleanup-on-fail \
   cram jupyterhub/jupyterhub \
  --namespace cram \
  --version=2.0.0 \
  --values config.yaml
  
# Delete a helm namespace
helm delete cram --namespace cram
kubectl delete namespace cram

# Set default kubernetes namespace to cram
microk8s.kubectl config set-context $(kubectl config current-context) --namespace cram

# Monitor kubernetes pods of default namespace
watch microk8s.kubectl get pod --namespace cram

# Delete a pod
kubectl delete pod jupyter-admin 

# Get all service
microk8s.kubectl get services

# Get address of JupyterHub
microk8s.kubectl get service proxy-public

# Forward the JupyterHub service to localhost:8080
microk8s.kubectl port-forward service/proxy-public 8080:http

microk8s kubectl expose service/proxy-public --type=LoadBalancer --name=proxy-public-lb --external-ip=192.168.102.13

# Output logs of a node
microk8s.kubectl logs jupyter-admin
microk8s.kubectl logs jupyter-admin --all-containers
kubectl describe pod jupyter-admin

# Others
microk8s status --wait-ready
microk8s kubectl get nodes
