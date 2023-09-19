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
    sudo ufw enable

Restart the mirck8s after the firewall update.

*Note*: If your reboot your machine, the firewall issue would possibly appear again. It is very likely a bug of Ubuntu 22.04, details and solutions can be found here: https://bugs.launchpad.net/ufw/+bug/1987227. Simple solution: before reboot, disable the the `ufw` by `sudo ufw disable`, config the firewall again after reboot and then enable ufw.

## 2. Enable Microk8s add-ons

Enable the necessary Add ons

    microk8s enable dns
    microk8s enable helm3

Configure networking:

    microk8s enable metallb:10.0.0.100-10.0.0.200

The host IP address should be within this IP range. You can check out the host network interface with command `ifconfig`.

Configure Storage:

    sudo systemctl enable iscsid.service
    microk8s enable openebs

Modify the basepath in file local-storage-dir.yaml

    microk8s.kubectl apply -f ./local-storage-dir.yaml

List the storageClass, ensure the default storage class is "local-storage-dir":

    microk8s.kubectl get storageClass

At this point, if all the pods are running and ready, the kubernetes setup is done.

## 3. Setup Helm

The mircok8s shipped with a `Helm`, add repo:

    microk8s.helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
    microk8s.helm repo update

## 4. Setup BinderHub

Edit the config file [binder.yaml](./binder.yaml), you need a dockerhub account and provide a token in the config file. For other configurations, read the documentation:
[Zero to BinderHub](https://binderhub.readthedocs.io/en/latest/index.html).

Deploy the the JupyterHub with `Helm`:

    microk8s.helm upgrade --cleanup-on-fail \
        --install mybinderhub jupyterhub/binderhub \
        --version=1.0.0-0.dev.git.3170.h84b1db9 \
        --namespace=mybinderhub \
        --create-namespace \
        -f ./binder.yaml

This command might take a while and won't output anything until it finished. But you can see the progress by monitoring the pods and a new namespace `mybinderhub` should be created. Here I set both the helm release and kubernetes namespace as `mybinderhub`. Name it something else if you prefer.

Run this command to see the external IP of service `proxy-public`:

     microk8s.kubectl get svc -n mybinderhub

Output:

    NAME           TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
    hub            ClusterIP      10.152.183.29    <none>        8081/TCP       3m50s
    proxy-public   LoadBalancer   10.152.183.152   10.0.0.100    80:30774/TCP   3m50s
    proxy-api      ClusterIP      10.152.183.241   <none>        8001/TCP       3m50s
    binder         LoadBalancer   10.152.183.75    10.0.0.101    80:31084/TCP   3m50s

Update `config.BinderHub.hub_url` to Jupyterhub external IP in the [binder.yaml](./binder.yaml), for example:

    ...
    config:
        BinderHub:
            use_registry: true
            image_prefix: binder-
            hub_url: http://10.0.0.100
    ...

Update Binderhub Deployment again:

    microk8s.helm upgrade mybinderhub --cleanup-on-fail \
        jupyterhub/binderhub --version=1.0.0-0.dev.git.3170.h84b1db9 \
        --namespace=mybinderhub \
        -f ./binder.yaml

## 5. Verify the setup

Monitor all pods under namespace `mybinderhub`:

    watch microk8s.kubectl get pod -n mybinderhub

A noraml output should looks like this, wait until every pod is ready:

    NAME                             READY   STATUS    RESTARTS   AGE
    user-scheduler-574bb59c5-q2vr4   1/1     Running   0          12m
    user-scheduler-574bb59c5-mwb8l   1/1     Running   0          12m
    proxy-5c5d8c6899-tgf2z           1/1     Running   0          2m8s
    hub-69dd7cd8b7-hb2dv             1/1     Running   0          2m8s
    binder-7456dd9f6-kmxjp           1/1     Running   0          119s

## 6. Access to the BinderHub

If kubernetes is running on your local machine, you can access to the BinderHub with the ip of the service `binder`. e.g. <http://10.0.0.101/>

If kubernetes is running on a remote server, forward the `proxy-public` service to the server's host network:

    microk8s.kubectl port-forward service/proxy-public 8080:http --address='0.0.0.0'

and forward port 8080 to your local machine via SSH.

    ssh -L 8080:127.0.0.1:8080 {username}@{server_ip}

If you want the Binderhub can be easily access by others, better setup a proxy server and bind domain name to it.

## 7. Optional Setup

Install Kubernetes [Dashboard](https://microk8s.io/docs/addon-dashboard):

    microk8s enable dashboard
    microk8s kubectl create token default

Add the following lines to your `.bashrc` (or other shell .rc files), to avoid typing microk8s prefix

    alias kubectl='microk8s.kubectl'
    alias helm='microk8s.helm'

You can set the default namespace as `mybinderhub`, to skip the namespace paramenter "-n mybinderhub"

    kubectl config set-context $(kubectl config current-context) --namespace mybinderhub

## 8. Update deployment

Everytime you update the config file [binder.yaml](./binder.yaml), needs to run the helm update to make changes alive:

    microk8s.helm upgrade mybinderhub --cleanup-on-fail \
        jupyterhub/binderhub --version=1.0.0-0.dev.git.3170.h84b1db9 \
        --namespace=mybinderhub \
        -f ./binder.yaml

## 9. Uninstallation and removing resources

To delete a kubernetes pod:

    microk8s.kubectl delete pod jupyter-user1 -n mybinderhub

To delete a pvc (user storage):

    microk8s.kubectl delete pvc claim-user1 -n mybinderhub

To delete a kubernetes namespace:

    microk8s.kubectl delete namespace mybinderhub

To delete a helm release:

    microk8s.helm delete mybinderhub --namespace mybinderhub

To reset the Microk8s (this will delete all namespaces and pods):

    sudo microk8s reset

To uninstall the Microk8s (and remove the alias in `.bashrc`):

    sudo snap remove microk8s
