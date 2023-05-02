# Install JupyberHub
helm upgrade --cleanup-on-fail \
  --install cram jupyterhub/jupyterhub \
  --namespace cram \
  --create-namespace \
  --version=2.0.0 \
  --values ./cram/base_jupyter/kubernetes_config/config.yaml

# Upgrade JupyberHub
helm upgrade --cleanup-on-fail \
   cram jupyterhub/jupyterhub \
  --namespace cram \
  --version=2.0.0 \
  --values ./cram/base_jupyter/kubernetes_config/config.yaml

# Install BinderHub
helm upgrade --cleanup-on-fail \
  --install cram \
  jupyterhub/binderhub --version=1.0.0-0.dev.git.3080.h8f9a1dc \
  --namespace=cram \
  --create-namespace \
  -f ./cram/base_jupyter/kubernetes_config/binder.yaml

# Upgrade BinderHub
helm upgrade cram --cleanup-on-fail \
  jupyterhub/binderhub --version=1.0.0-0.dev.git.3080.h8f9a1dc \
  --namespace=cram \
  -f ./cram/base_jupyter/kubernetes_config/binder.yaml

# Monitor pods status
watch kubectl get pods -n cram
watch kubectl get pods --all-namespaces
kubectl get pods -o wide --namespace cram

# Get cluster info
kubectl cluster-info

# Get all namespaces
kubectl get namespaces

# Get all pods or services
watch "microk8s.kubectl get namespaces && \
microk8s.kubectl get services --all-namespaces && \
microk8s.kubectl get pods --all-namespaces"

# Get all info
kubectl get all -A

# Start a bash session in the Pod’s container
kubectl exec -ti -n cram hub-8686c49c66-dfwgf -- bash

# Delete a pod
kubectl delete pod jupyter-admin
# Delete pods name with keyword "jupyter-yxzhan"
kubectl get pods --no-headers=true | awk '/jupyter-yxzhan/{print $1}'| xargs kubectl delete pod

# Get all service
kubectl get services --all-namespaces

# Forward the JupyterHub service to localhost:8080 and ${IP}:8080
kubectl port-forward service/proxy-public 8080:http --address='0.0.0.0'
# sudo kubectl port-forward service/proxy-public 80:http --address='0.0.0.0'

# Access to dashboard
kubectl create token default
kubectl port-forward service/kubernetes-dashboard -n kube-system 8080:443 --address='0.0.0.0'

# Output logs of a pod
kubectl logs jupyter-admin
kubectl logs -n cram hub-8686c49c66-dfwgf -f
kubectl describe pod jupyter-admin

 kubectl --namespace=cram describe service proxy-public
# Storage related
kubectl get storageClass
kubectl get pods -n openebs
kubectl get sc
kubectl get pvc

# Install k3s
curl -sfL https://get.k3s.io | sh -s - \
    --disable=traefik \
    --write-kubeconfig-mode=644 \
    --prefer-bundled-bin \
    --default-local-storage-path=$HOME/k3s_storage \
    --docker
# Add to .bashrc
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Uninstall k3s
k3s-uninstall.sh
# ... and a temporary workaround of https://github.com/rancher/k3s/issues/1469
docker stop $(docker container list --all --quiet --filter "name=k8s_") | xargs docker rm

# microk8s related
microk8s enable openebs
microk8s status --wait-ready
microk8s inspect
microk8s dashboard-proxy
microk8s.ctr images list
microk8s ctr images ls name~='yxzhan' 
microk8s ctr images rm $(microk8s ctr images ls name~='yxzhan' | awk {'print $1'})

# Delete a helm release
helm delete cram --namespace cram & \
kubectl delete namespace cram

# Set default kubernetes namespace to cram
kubectl config set-context $(kubectl config current-context) --namespace cram

# Config storage class
microk8s.kubectl apply -f ./cram/base_jupyter/kubernetes_config/local-storage-dir.yaml