# Base docker image for robotics programming on Jupyterhub/Binderhub

`intel4coro/base-notebook:20.04-noetic` is  a ready-to-run Docker image based on offical jupyter image [jupyter/minimal-notebook:ubuntu-20.04](https://hub.docker.com/layers/jupyter/minimal-notebook/ubuntu-20.04/images/sha256-a2d9cec8c5d373e073859adc67b6bc89a6f1b60f7cdfbfa024d6bc911a1c56fa?context=explore),  containing:

- [ros-noetic-desktop-full](http://wiki.ros.org/noetic/Installation/Ubuntu)
- [XPRA Remote Desktop](https://github.com/Xpra-org/xpra)
- [Oh-my-bash](https://github.com/ohmybash/oh-my-bash)
- [Robot Web Tools](https://robotwebtools.github.io/)

## Live Demo

[![Binder](https://binder.intel4coro.de/badge_logo.svg)](https://binder.intel4coro.de/v2/gh/IntEL4CoRo/docker-stacks.git/master)

## Development

### Run Image Locally (Under repo directory)

- Run and Build Docker image

  ```bash
  docker compose -f docker-compose.yml up --build
  ```

  or run with X-forwarding:

  ```bash
  xhost +local:docker && \
  docker compose -f docker-compose.yml up --build && \
  xhost -local:docker
  ```

- Open Web browser and go to http://localhost:8888/

- Force image rebuild

  ```bash
  docker compose -f docker-compose.yml up -d --build --no-cache
  ```

### Files Descriptions

- [Dockerfile](./Dockerfile): This file defines almost everything, including the base linux kernel, ROS distribution, python packages.
- [jupyter-settings.json](./jupyter-settings.json): Overwrites the default settings of the jupyterlab, for example the dark theme or light theme. Default UI language.
- [entrypoint.sh](./entrypoint.sh): The entrypoints of the docker image, defines the extra startup programs of the container. By default it will start the ROS core and the ROS web tools.
- [docker-compose.yml](./docker-compose.yml): Only for testing the docker image on local machine, the config here will not take effect in containers running on Binderhub.
- [bashrc.sh](./bashrc.sh): Where you can define some custom bash startup scripts. For example, define system envrionment variables or aliases for some command, change the theme of the bash.