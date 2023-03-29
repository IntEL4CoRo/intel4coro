# Install helm namespace
helm upgrade --cleanup-on-fail \
  --install cram jupyterhub/jupyterhub \
  --namespace cram\
  --create-namespace \
  --version=2.0.0 \
  --values ./cram/base_jupyter/kubernetes_config/config.yaml

# Upgrade helm namespace
helm upgrade --cleanup-on-fail \
   cram jupyterhub/jupyterhub \
  --namespace cram \
  --version=2.0.0 \
  --values ./cram/base_jupyter/kubernetes_config/config.yaml

# Monitor kubernetes pods of default namespace
watch microk8s.kubectl get pod --namespace cram

# Delete a pod
kubectl delete pod jupyter-admin 

# Get all service
microk8s.kubectl get services
microk8s.kubectl get service proxy-public

# Forward the JupyterHub service to localhost:8080 and ${IP}:8080
microk8s.kubectl port-forward service/proxy-public 8080:http --address='0.0.0.0'
# sudo microk8s.kubectl port-forward service/proxy-public 80:http --address='0.0.0.0'

# Output logs of a node
microk8s.kubectl logs jupyter-admin
microk8s.kubectl logs jupyter-admin --all-containers
kubectl describe pod jupyter-admin

# Dashboard proxy
microk8s dashboard-proxy

# Storage related
microk8s enable openebs
kubectl get pods -n openebs
kubectl get sc
kubectl get pvc
microk8s.kubectl apply -f ./cram/base_jupyter/kubernetes_config/local-storage-dir.yaml

# Others
microk8s status --wait-ready
microk8s kubectl get nodes


# Delete a helm release
helm delete cram --namespace cram

# Delete a k8s namespace
kubectl delete namespace cram

# Set default kubernetes namespace to cram
microk8s.kubectl config set-context $(kubectl config current-context) --namespace cram