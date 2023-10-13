# Base docker image for robotics programming on Jupyterhub/Binderhub

`intel4coro/base-notebook:22.04-iron` is  a ready-to-run Docker image based on offical jupyter image [jupyter/minimal-notebook:ubuntu-22.04](https://hub.docker.com/layers/jupyter/minimal-notebook/ubuntu-22.04/images/sha256-05d288f98c23ae4cb75a64766bb7fd07f325070714acbbdb216c14e996adf513?context=explore),  containing:

- [ros-iron-desktop](http://wiki.ros.org/noetic/Installation/Ubuntu)
- [XPRA Remote Desktop](https://github.com/Xpra-org/xpra)
- [Oh-my-bash](https://github.com/ohmybash/oh-my-bash)

## Usage

- Getting started [ROS2 Iron](https://docs.ros.org/en/iron/Tutorials.html) with binderhub
[![Binder](https://binder.intel4coro.de/badge_logo.svg)](https://binder.intel4coro.de/v2/gh/IntEL4CoRo/docker-stacks.git/ros-icon)

## Development

### Run Image Locally (Under repo directory)

- Run Docker image

  ```bash
  docker compose up
  ```

- Open Web browser and go to http://localhost:8888/

- Force image rebuild

  ```bash
  docker compose up -d --build 
  ```
