# Base docker image for robotics programming on Jupyterhub/Binderhub

`intel4coro/base-notebook:20.04-noetic-full-xpra` is  a ready-to-run Docker image based on offical jupyter image [jupyter/minimal-notebook:ubuntu-20.04](https://hub.docker.com/layers/jupyter/minimal-notebook/ubuntu-20.04/images/sha256-a2d9cec8c5d373e073859adc67b6bc89a6f1b60f7cdfbfa024d6bc911a1c56fa?context=explore),  containing:

- [ros-noetic-desktop-full](http://wiki.ros.org/noetic/Installation/Ubuntu)
- [XPRA Remote Desktop](https://github.com/Xpra-org/xpra)
- [Oh-my-bash](https://github.com/ohmybash/oh-my-bash)
- [Robot Web Tools](https://robotwebtools.github.io/)
<!-- - [Gzweb (Web client for Gazebo)](https://classic.gazebosim.org/gzweb) -->

## Live Demo

[Try on Binderhub](https://binder.intel4coro.de/v2/gh/IntEL4CoRo/docker-stacks.git/remote-desktop)

<!-- ## Gazebo -->

<!-- Gazebo client may not work on some machines due to LLVM memory allocate issue. -->

<!-- ### To Run Gazebo

Open a Teriminal and run gazebo server:

  ```bash
  gzserver --verbose
  ```

Open another Teriminal run gzweb client server:

  ```bash
  conda activate gzweb
  cd /home/jovyan/gzweb
  npm start
  ``` -->

## Development

### Run Image Locally (Under repo directory)

- Run and Build Docker image

  ```bash
  docker compose up
  ```

- Open Web browser and go to http://localhost:8888/

- Force image rebuild

  ```bash
  docker compose -f docker-compose.yml up -d --build 
  ```
