# Intel4coro Project - CRAM on JupyterHub


## To run CRAM on ZMML Jupyterhub server

1. Login: https://jupyter.zmml.uni-bremen.de/ (only accesible for users who have access rights)
(Run docker container locally) 

2. Select Intel4coro:Cram

## Setting up for local development
Please fow the following links to install `docker` and `docker-compose` to your system.
- [https://docs.docker.com/engine/install/](https://docs.docker.com/engine/install/)
- [https://docs.docker.com/compose/install/](https://docs.docker.com/compose/install/)

###  Option1: Run with docker-compose
1. Clone this repo
3. Go to folder of `dockerfile`, Build the image
```
docker build -t <image_name> .
```
4. Modify the docker-compose.yml to change the image_name and run:
```
docker-compose up
```
5. To stop and remove the container run:
```
docker-compose down
```

###  Option2: Run on JupyterHub with Kubernetes
1. Follow the following tutorial to setup JupyterHub with Kubernetes
- [https://z2jh.jupyter.org/en/stable/#](https://z2jh.jupyter.org/en/stable/#)
2. Build the image locally and push it to your DockerHub Respository (Or other container registry)
- (Optional) To run a localhost registry:
```
docker run -d -p 5000:5000 --restart=always --name registry registry:2
```
3. Modify your `config.yaml` file to deploy the built image.
4. Example of `config.yaml` file are under directory [./kubernetes_config](./kubernetes_config). Commonly used kubernetes commands are in [./kubernetes_config/commands.sh](./kubernetes_config/commands.sh).
