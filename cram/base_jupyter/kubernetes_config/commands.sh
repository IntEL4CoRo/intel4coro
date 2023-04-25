# Install helm namespace
helm upgrade --cleanup-on-fail \
  --install cram jupyterhub/jupyterhub \
  --namespace cram \
  --create-namespace \
  --version=2.0.0 \
  --values ./cram/base_jupyter/kubernetes_config/config.yaml

# Upgrade helm namespace
helm upgrade --cleanup-on-fail \
   cram jupyterhub/jupyterhub \
  --namespace cram \
  --version=2.0.0 \
  --values ./cram/base_jupyter/kubernetes_config/config.yaml

# Install and upgrade BinderHub helm
helm install cram \
    jupyterhub/binderhub --version=1.0.0-0.dev.git.3049.hf45dc0b \
    --namespace=cram \
    --create-namespace \
    -f ./cram/base_jupyter/kubernetes_config/secret.yaml \
    -f ./cram/base_jupyter/kubernetes_config/binder.yaml

helm upgrade cram jupyterhub/binderhub --version=1.0.0-0.dev.git.3049.hf45dc0b \
    -f ./cram/base_jupyter/kubernetes_config/secret.yaml \
    -f ./cram/base_jupyter/kubernetes_config/binder.yaml

helm delete cram --namespace cram && \
kubectl delete namespace cram

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

# Dtart a bash session in the Pod’s container
kubectl exec -ti jupyter-yxzhan-2dmoodle-5fjupyter-2dh9yx489v -- bash

# Delete a pod
kubectl delete pod jupyter-yxzhan-2dmoodle-5fjupyter-2dg7u04owk
# Delete pods name with keyword "jupyter-yxzhan"
microk8s.kubectl get pods --no-headers=true | awk '/jupyter-yxzhan/{print $1}'| xargs microk8s.kubectl delete pod


# Get all service
kubectl get services --all-namespaces

# Forward the JupyterHub service to localhost:8080 and ${IP}:8080
kubectl port-forward service/proxy-public 8080:http --address='0.0.0.0'
# sudo kubectl port-forward service/proxy-public 80:http --address='0.0.0.0'

# Output logs of a pod
kubectl logs jupyter-admin
kubectl describe pod jupyter-admin

 kubectl --namespace=cram describe service proxy-public
# Storage related
kubectl get storageClass
kubectl get pods -n openebs
kubectl get sc
kubectl get pvc

# Install k3s
curl -sfL https://get.k3s.io | sh -s - \
    --write-kubeconfig-mode=644 \
    --prefer-bundled-bin \
    --docker
    # --default-local-storage-path=/home/yanxiang/k3s_storage
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

# Delete a helm release
helm delete cram --namespace cram

# Delete a k8s namespace
kubectl delete namespace cram

# Set default kubernetes namespace to cram
kubectl config set-context $(kubectl config current-context) --namespace cram

microk8s.kubectl apply -f ./cram/base_jupyter/kubernetes_config/local-storage-dir.yaml

kubectl apply -f ./cram/base_jupyter/kubernetes_config/addresspool.yaml