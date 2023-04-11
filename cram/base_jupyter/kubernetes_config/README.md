# Setup JupyterHub for Kubernetes on a Ubuntu server

## 1. Install Microk8s

We are using the [Microk8s](https://microk8s.io/docs/) to setup our self-host kubernetes. As the offical jupyterhub [stable docs](https://z2jh.jupyter.org/en/stable/kubernetes/other-infrastructure/step-zero-microk8s.html) recommended it. If you are prefer k3s, you can try out this tutorial [zero-to-jupyterhub-k8s/CONTRIBUTING.md](https://github.com/jupyterhub/zero-to-jupyterhub-k8s/blob/main/CONTRIBUTING.md).

Install Microk8s:

    sudo snap install microk8s --classic

Join the group `microk8s`:

    sudo usermod -a -G microk8s $USER
    sudo chown -f -R $USER ~/.kube

Re-enter the session for the group update to take place:

    su - $USER

or simply login out and login again.

check out Microk8s status

    microk8s status --wait-ready

For more details check out the [get started tutorial](https://microk8s.io/docs/getting-started).

### Troubleshot

To ensure the kubernetes cluster is running properly, run:

    microk8s.kubectl get pods --all-namespaces
    <!-- Or monitor continueously -->
    watch "microk8s.kubectl get pods --all-namespaces"

If some pods are got errors, check the logs or describe the pods:

    microk8s.kubectl describe pod -n kube-system malico-kube-controllers-{SomeRandomString}
    microk8s.kubectl logs --previous -n kube-system calico-kube-controllers-{SomeRandomString}

**Firewall Issue**: 

Under Ubuntu 22.04, the firewall could possibily block pods communication.
Solution can be found here: <https://cylab.be/blog/246/install-kubernetes-on-ubuntu-2204-with-microk8s>.

    sudo ufw allow in on cni0
    sudo ufw allow out on cni0
    sudo ufw default allow routed
    sudo ufw allow ssh
    sudo ufw enable

Restart the mirck8s after the firewall update.

*Note*: If your reboot your machine, the firewall issue would possibly appear again. It is very likely a bug of Ubuntu 22.04, details and solutions can be found here: https://bugs.launchpad.net/ufw/+bug/1987227. Simple solution: before reboot, disable the the `ufw` by `sudo ufw disable`, config the firewall again after reboot and then enable ufw.

## 2. Enable Microk8s add-ons

Enable the necessary Add ons

    microk8s enable dns
    microk8s enable helm3

Configure networking:

    microk8s enable metallb:192.168.102.0-192.168.102.100
    
The host IP address should be within this IP range. You can check out the host network interface with command `ifconfig`.

Configure Storage:

    sudo systemctl enable iscsid.service
    microk8s enable openebs

Modify the basepath in file local-storage-dir.yaml

    microk8s.kubectl apply -f ./cram/base_jupyter/kubernetes_config/local-storage-dir.yaml

List the storageClass, ensure the default storage class is "local-storage-dir":

    microk8s.kubectl get storageClass

At this point, if all the pods are running and ready, the kubernetes setup is done.

## 3. Setup Helm

The mircok8s shipped with a `Helm`, add repo:

    microk8s.helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
    microk8s.helm repo update

## 4. Setup JupyterHub

Deploy the the JupyterHub with `Helm`:

    microk8s.helm upgrade --cleanup-on-fail \
    --install cram jupyterhub/jupyterhub \
    --namespace cram \
    --create-namespace \
    --version=2.0.0 \
    --values ./cram/base_jupyter/kubernetes_config/config.yaml

This command would take a quite a long time and won't output anything until it finished. Becaues it needs to pull large images from docker hub. But you can see the progress by monitoring the pods and a new namespace `cram` was created. Here I set both the helm release and kubernetes namespace as `cram`.

Run this command to ensure all the pods under namespace `cram` are ready:

     microk8s.kubectl get pods -n cram

The normal status should looks like this:

    NAME                              READY   STATUS    RESTARTS   AGE
    user-scheduler-79d9d8dd9f-4fll9   1/1     Running   0          2m26s
    proxy-58ddf67d4b-l4gpf            1/1     Running   0          2m26s
    user-scheduler-79d9d8dd9f-462bb   1/1     Running   0          2m26s
    continuous-image-puller-px8dj     1/1     Running   0          2m26s
    hub-7c856d58f9-sff2l              1/1     Running   0          2m26s

## 5. Verify the setup

Check out the services under namespace `cram`:

    microk8s.kubectl get services -n cram

The output looks like this:

    NAME           TYPE           CLUSTER-IP       EXTERNAL-IP        PORT(S)        AGE
    hub            ClusterIP      10.152.183.185   <none>             8081/TCP       10m
    proxy-api      ClusterIP      10.152.183.206   <none>             8001/TCP       10m
    proxy-public   LoadBalancer   10.152.183.74    192.168.102.50     80:30265/TCP   10m

To visit the JupyterHub, forward the `proxy-public` service to your local network.

    microk8s.kubectl port-forward service/proxy-public 8080:http --address='0.0.0.0'

If you are inside the cluster network you can also access to the JupyterHub with the ip of the service `hub` or `proxy-public`. e.g. <http://10.152.183.185:8081/> or <http://10.152.183.74/>.

Or config the `proxy` to make the JupyterHub expose to the external network.

### Optional

If you don't what to type commands with prefix microk8s, add the following lines to your `.bashrc` (or other shell rc files)

    alias kubectl='microk8s kubectl'
    alias helm='microk8s helm'

If you don't what to provide the namespace everytime your use `kubectl` commands, you can set the default namespace as `cram`

    kubectl config set-context $(kubectl config current-context) --namespace cram

## 6. Update Config.yaml

Everytime you update the config file `config.yaml`, you should run the helm update to make changes alive:

    microk8s.helm upgrade --cleanup-on-fail \
        cram jupyterhub/jupyterhub \
        --namespace cram \
        --version=2.0.0 \
        --values ./cram/base_jupyter/kubernetes_config/config.yaml

## 7. Uninstallation and removing resources manually

To delete a kubernetes pod:

    microk8s.kubectl delete pod jupyter-user1 

To delete a pvc (user storage):

    microk8s.kubectl delete pvc claim-user1

To delete a kubernetes namespace:

    microk8s.kubectl delete namespace cram

To delete a helm release:

    microk8s.helm delete cram --namespace cram

To reset the Microk8s (this will delete all namespaces and pods):

    sudo microk8s reset

To uninstall the Microk8s (and remove the alias in `.bashrc`):

    sudo snap remove microk8s

## 8. Future works

- Setup the HTTPS
- Config the proxy
