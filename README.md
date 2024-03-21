# Setup a self-hosting BinderHub

[Binderhub](https://github.com/jupyterhub/binderhub) allows you to `BUILD` and `REGISTER` a Docker image from a Git repository, then CONNECT with JupyterHub, allowing you to create a public IP address that allows users to interact with the code and environment within a live JupyterHub instance. You can select a specific branch name, commit, or tag to serve.

Live demos: 
- https://mybinder.org/
- https://binder.intel4coro.de/

For the usage of Binderhub services please read the [user guide](https://mybinder.readthedocs.io/en/latest/).

This is a tutorial to help you set up a Binderhub service on your machines instead of using any cloud providers.

This could be useful when you want a Binderhub:
 - only accessible within a local area network.
 - connect to some resources that are only available inside your institute, for example, some physical robots.
 - access to sensitive data. 

This tutorial references the two official tutorials: [Zero to JupyterHub with Kubernetes](https://z2jh.jupyter.org/en/stable/index.html) and
[Zero to BinderHub](https://binderhub.readthedocs.io/en/latest/zero-to-binderhub/index.html)

> [!NOTE]
> The Binderhub project is under active development, there are new releases almost every week. Therefore, the official documentation is not always up-to-date.

## 0. Requirement
- An X86 machine with Ubuntu installed
- A [DockerHub](https://hub.docker.com/) account
- Machine Public IP address (optional)
- Two domain names (optional)

**Tested setup**
|Components|Version|
|-|-|
| BinderHub | Helm chart 1.0.0-0.dev.git.3167.hc46696b |
| Kubernetes | MicroK8s v1.26.11 revision 6236 |
| Operating System | Ubuntu 20.04.6 LTS, Ubuntu 22.04.2 LTS |
| Hardware | x86 Intel and AMD CPU with 32G memory |

## 1. Install Kubernetes

[Kubernetes](https://kubernetes.io/), also known as K8s, is an open-source system for automating the deployment, scaling, and management of containerized applications. There are many different implementations of Kubernetes (e.g., Minikube, Mircok8s, k3s), but they all share the same standard.
In this tutorial, we will use [Microk8s](https://microk8s.io/docs/). If you prefer k3s, feel free to try out this tutorial [zero-to-jupyterhub-k8s/CONTRIBUTING.md](https://github.com/jupyterhub/zero-to-jupyterhub-k8s/blob/main/CONTRIBUTING.md).
> Note: Different Kubernetes implementations could have different container runtimes and networking solutions.

**Install MicroK8s:**

```bash
sudo snap install microk8s --classic
```

For Windows and MacOS users, see the [Installation Guide](https://microk8s.io/#install-microk8s).

**Join the user group `microk8s`:**

```bash
sudo usermod -a -G microk8s $USER
sudo chown -f -R $USER ~/.kube
```

This step is to free you from running commands `microk8s` and `kubectl` with `sudo`.

**Re-enter the session for the group update to take place:**

```bash
su - $USER
```

or simply logout and login again.

**Check Microk8s status**

```bash
microk8s status --wait-ready
```

For more details check out the [get started tutorial](https://microk8s.io/docs/getting-started).

**Check Kubernetes cluster status**

After the installation of Microk8s, the Kubernetes core system will start automatically. Check if all the [Pods](https://kubernetes.io/docs/concepts/workloads/pods/) are running properly:

```bash
microk8s.kubectl get pods -A
```

Or monitor status continueously:

```bash
watch "microk8s.kubectl get pods -A"
```

The output table should be similar to the following table, when all pods are `READY` and `Running` that means the Kubernetes setup is done.
```
NAMESPACE            NAME                                              READY   STATUS    RESTARTS       AGE
kube-system          metrics-server-848968bdcd-4v66m                   1/1     Running   6 (42d ago)    99d
kube-system          calico-node-br2kb                                 1/1     Running   0              16d
kube-system          calico-kube-controllers-97bc755b5-vpbl5           1/1     Running   0              16d
```

### Troubleshoot

If some pods have errors, check the logs or describe the pods to see the error messages:

    microk8s.kubectl describe pod -n kube-system malico-kube-controllers-{SomeRandomString}
    microk8s.kubectl logs --previous -n kube-system calico-kube-controllers-{SomeRandomString}

**Firewall Issue**:

Under Ubuntu 22.04, the firewall could block pod communication.
Solution can be found here: <https://cylab.be/blog/246/install-kubernetes-on-ubuntu-2204-with-microk8s>.

Edit the firewall rules with `ufw`:

    sudo ufw allow in on cni0
    sudo ufw allow out on cni0
    sudo ufw default allow routed
    sudo ufw enable

Restart the mirck8s after the firewall update.

    microk8s stop
    # wait for the kube-system to shutdown completely
    microk8s start

*Note*: If you reboot the machine, the firewall issue will possibly appear again. It might caused by the conflict of rules defined in `ufw` and `iptables`. Details and solutions can be found here: https://bugs.launchpad.net/ufw/+bug/1987227. A simple solution: before reboot, disable the `ufw` by `sudo ufw disable`, configure the firewall again after reboot, and then enable `ufw`.

## 2. Enable Microk8s add-ons

The Kubernetes is by default running only a few core servies, we need to start some extra services required by the Binderhub, and these services are provided by the Microk8s as add-ons.

**Required Add-ons:**

- [dns](https://microk8s.io/docs/addon-dns):  This deploys CoreDNS to supply address resolution services to Kubernetes.
- [helm3](https://helm.sh/): A tool help you manage Kubernetes applications.
- community: Enables the Microk8s community addons repository.
- [metallb](https://microk8s.io/docs/addon-metallb): A network LoadBalancer implementation that tries to “just work” on bare metal clusters.
- [OpenEBS](https://microk8s.io/docs/addon-openebs): Turns any storage available to Kubernetes worker nodes into Local or Distributed Kubernetes Persistent Volumes.

```bash
 microk8s enable dns
 microk8s enable helm3
 microk8s enable community
```
Enable `metallb` and configure IP range:
```bash
microk8s enable metallb:10.0.0.100-10.0.0.200
```
If you want the Binderhub accessible within a local network, the IP range should be within your LAN IP range(e.g., 192.168.100.20-192.168.100.50). You can check the network interface of your machine with the command `ifconfig`. A more practical setup is to expose the Binderhub to an external network by a proxy server, we will discuss this in a later section.

Enable Storage services:

    sudo systemctl enable iscsid.service
    microk8s enable openebs

Modify the `basepath` in file [local-storage-dir.yaml](./local-storage-dir.yaml) to a directory where the Kubernetes can store data and apply the configure:

    microk8s.kubectl apply -f ./local-storage-dir.yaml

List the `storageClass`, and ensure the default storage class is "local-storage-dir":

    microk8s.kubectl get storageClass

The newly installed addons will start some pods and services, ensure the pods and services are ready:

    microk8s.kubectl get pods -A
    microk8s.kubectl get svc -A

At this point, if all the pods are running and ready, then the Kubernetes setup is done. Otherwise, you have to check the error with the commands like `microk8s.kubectl describe` and `microk8s.kubectl logs`.

## 3. Setup Helm

[Helm](https://helm.sh/) Charts help you define, install, and upgrade even the most complex Kubernetes application.
The mircok8s shipped with a `Helm`, simply add Binderhub helm repo:

    microk8s.helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
    microk8s.helm repo update

## 4. Set up the container registry

By default, Binderhub will push all the built Docker images to a container registry. While this is not required, it ensures that a Kubernetes hang on this machine doesn't affect the containerized repos that have already been built. From there, you can quickly recover or deploy the same Binderhub instance on another machine.
In this tutorial, we use [Dockerhub](https://hub.docker.com/) as our container registry, if you want to use other registries see [setup-registry](https://binderhub.readthedocs.io/en/latest/zero-to-binderhub/setup-registry.html) for more details.

Make sure you have a Dockerhub account. Go to https://hub.docker.com/settings/security to generate a new Access Token.

Replace `<dockerhub-username>` and `<dockerhub-token>` in the config file [binder.yaml](./binder.yaml) with your dockerhub username and token. For the `hub_url`, it can be set to `10.0.0.101` for now, you have to change it later according to your network configuration. 

```yaml
registry:
  username: <dockerhub-username>
  password: <dockerhub-token>

config:
  BinderHub:
    use_registry: true
    image_prefix: <dockerhub-username>/binder-
    hub_url: <jupyterhub-url>
```

## 5. Install BinderHub

Finally, we can start to install the Binderhub.
[binder.yaml](./binder.yaml) is a minimum config file, please read the documentation
[Zero to BinderHub](https://binderhub.readthedocs.io/en/latest/customization/index.html).
and check the [config of mybinder.org](https://github.com/jupyterhub/mybinder.org-deploy/blob/main/mybinder/values.yaml) for more advanced usage.

The `Helm` command deploying the Binderhub is in such a pattern:
```bash
    microk8s.helm upgrade --cleanup-on-fail \
      --install ${Helm namespace} \
      jupyterhub/binderhub --version=${binderhub helm release} \
      --namespace=${kubernetes namespace} \
      --create-namespace \
      -f ${the config file}
```
For example:
```bash
    microk8s.helm upgrade --cleanup-on-fail \
      --install binder \
      jupyterhub/binderhub --version=1.0.0-0.dev.git.3167.hc46696b \
      --namespace=binder \
      --create-namespace \
      -f ./binder.yaml
```

The Kubernetes namespace and Helm namespace are customized names that help you manage the deployment. In the example above,  both the helm namespace and Kubernetes namespace are `binder`. Name it something else if you prefer. 
The parameter  `--version` denotes the release of the Binderhub helm chart, and the last string represents the [BinderHub commit SHA](https://github.com/jupyterhub/binderhub/commits/main/). The Binderhub helm chart releases can be found [here](https://hub.jupyter.org/helm-chart/#development-releases-binderhub).

This command might take a while and won't output anything until it is finished. You can check the installation progress by monitoring the pods and the services of the new namespace in a new terminal:

    microk8s.kubectl get pod -n binder

Run this command to see the external IP of service `proxy-public`:

     microk8s.kubectl get svc -n binder

Expected Output:

    NAME           TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
    hub            ClusterIP      10.152.183.29    <none>        8081/TCP       3m50s
    proxy-public   LoadBalancer   10.152.183.152   10.0.0.100    80:30774/TCP   3m50s
    proxy-api      ClusterIP      10.152.183.241   <none>        8001/TCP       3m50s
    binder         LoadBalancer   10.152.183.75    10.0.0.101    80:31084/TCP   3m50s

The Binderhub is built on top of the Jupyterhub, there are services exposed to the external network(with `EXTERNAL-IP`). The Binderhub needs to know the IP of the Jupyterhub (the service `proxy-public`). Therefore, we need to update the config file again to tell Binderhub the correct EXTERNAL-IP of Jupyterhub.

Update `config.BinderHub.hub_url` to Jupyterhub external IP in the [binder.yaml](./binder.yaml), for example:

    ...
    config:
        BinderHub:
            use_registry: true
            image_prefix: binder-
            hub_url: http://10.0.0.100
    ...

Apply the configuration again (this command looks similar to the installation one, but it has slight differences, be aware of that):

    microk8s.helm upgrade binder --cleanup-on-fail \
        jupyterhub/binderhub --version=1.0.0-0.dev.git.3167.hc46696b \
        --namespace=binder \
        -f ./binder.yaml

## 6. Verify the Installation

Monitor all pods under namespace `binder`:

    watch microk8s.kubectl get pod -n binder

A normal output should look like this, wait until every pod is ready:

    NAME                             READY   STATUS    RESTARTS   AGE
    user-scheduler-574bb59c5-q2vr4   1/1     Running   0          12m
    user-scheduler-574bb59c5-mwb8l   1/1     Running   0          12m
    proxy-5c5d8c6899-tgf2z           1/1     Running   0          2m8s
    hub-69dd7cd8b7-hb2dv             1/1     Running   0          2m8s
    binder-7456dd9f6-kmxjp           1/1     Running   0          119s

## 7. Access to the BinderHub

If kubernetes is running on your local machine, you can access to the BinderHub with the ip of the service `binder`. e.g. <http://10.0.0.101/>

If kubernetes is running on a remote server, forward the `binder` service to the server's host network:

    microk8s.kubectl port-forward service/proxy-public 8080:http --address='0.0.0.0'

and forward port 8080 to your local machine via SSH.

    ssh -L 8080:127.0.0.1:8080 {username}@{server_ip}


> [!TIP]
> If you want the Binderhub can be easily accessible, it is better to set up a proxy server and assign domain names. 
> 
>  A rough solution: 
>  1. Create 2 subdomain names (e.g., binder.yourdomain.org and jupyter.yourdomain.org)
>  2. Start a proxy server, (e.g., [Nginx Proxy Manager](https://nginxproxymanager.com/))
> 3. Point both domains to this server's public IP address and let the proxy server forward the network requests to Kubernetes service IPs.
> 4. Don't forget to change the `hub_url` to the Jupyterhub domain.


## 8. Optional Setup

### Install [Kubernetes Dashboard](https://microk8s.io/docs/addon-dashboard)

Kubernetes Dashboard is a very useful tool for managing your Kubernetes clusters in a web client.
```bash
 # Install dashboard
 microk8s enable dashboard
 # Find the IP of services "kubernetes-dashboard"
 kubectl get svc -n kube-system
 # Or forward services to a localhost port
 kubectl port-forward service/kubernetes-dashboard -n kube-system 10024:443 --address='0.0.0.0'
 # The Dashboard server use HTTPS only, so open web client like:
 # https://localhost:10024 or https://10.152.123.118
 # Generate a token to login to the web client
 microk8s kubectl create token default
```

## 9. Update Deployment

Every time you update the config file [binder.yaml](./binder.yaml) or want to upgrade to a newer [Binderhub release](https://hub.jupyter.org/helm-chart/#development-releases-binderhub), need to run the following two commands to make changes alive:

    helm repo update
 
    microk8s.helm upgrade binder --cleanup-on-fail \
        jupyterhub/binderhub --version=${A new binderhub release} \
        --namespace=binder \
        -f ./binder.yaml

> [!NOTE]
> Updating the Binderhub deployment could cause the current running user instances disconnected.

## 10. Uninstallation and removing resources

To delete a pod:

    microk8s.kubectl delete pod jupyter-xxx-xxx-2djymf5ug4 -n binder

To delete all pods match name "jupyter-xxxx-":

    kubectl get pods --no-headers=true | awk '/jupyter-xxxx-/{print $1}'| xargs kubectl delete pod

To delete a pvc (user storage):

    microk8s.kubectl delete pvc claim-user1 -n binder

> [!WARNING]
> To uninstall the Binderhub:
> 
> ```bash
>    helm delete binder --namespace binder && \
>    kubectl delete namespace binder
> ```
> 
> To reset the Microk8s (this will delete all namespaces and pods):
> 
> ```bash
>     sudo microk8s reset
> ```
>
> To uninstall the Microk8s (and remove the alias in `.bashrc`):
> 
> ```bash
>    sudo snap remove microk8s
> ```

More handy commands can be found in [commands.sh](commands.sh)

## 11. Architecture

>Todos:
