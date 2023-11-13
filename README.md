# Docker image of ROS2 iron on Jupyterhub/Binderhub

[![](https://img.shields.io/docker/pulls/intel4coro/base-notebook.svg)](https://hub.docker.com/r/intel4coro/base-notebook/tags)
[![Binder](https://binder.intel4coro.de/badge_logo.svg)](https://binder.intel4coro.de/v2/gh/IntEL4CoRo/docker-stacks.git/ros-iron)

`intel4coro/base-notebook:22.04-iron`  is a ready-to-run ROS2 Docker image built on top of jupyter image [jupyter/minimal-notebook:ubuntu-22.04](https://jupyter-docker-stacks.readthedocs.io/en/latest/using/selecting.html#jupyter-minimal-notebook) , contains the following main softwares:

- [ros-iron-desktop](https://docs.ros.org/en/iron/index.html): Desktop install of ROS, RViz, demos, tutorials.
- [Jupyterlab 4.0](https://github.com/jupyterlab/jupyterlab): Web-based integrated development environment (IDE)
- [XPRA Remote Desktop](https://github.com/Xpra-org/xpra): Virtual Display to display GUI applications on web browser
- [Gazebo](http://classic.gazebosim.org/): A Robotic Simulator

![screenshot-ros](./screenshots/screenshot.png)
![screenshot-gazebo](./screenshots/screenshot-gazebo.png)

## Quick Start

Start [ROS2 Iron tutorials](https://docs.ros.org/en/iron/Tutorials.html) on Binderhub: [![Binder](https://binder.intel4coro.de/badge_logo.svg)](https://binder.intel4coro.de/v2/gh/IntEL4CoRo/docker-stacks.git/ros-iron)

### Try out Gazebo Demos

Some Gazebo demos are under directory `gazebo_worlds_demo`, usage of demo can be found at the beginning of the `*.world` files.

Open an Terminal under this directory and launch demo:

```bash
gazebo --verbose gazebo_ros_wheel_slip_demo.world
```

## Build environments for your git Repo

To build your own ROS2 environment based on this image to run your open source code, you need to create a `Dockerfile` under the root path or directory `binder/` in your git repository.

### Example of Dockerfile

```Dockerfile
FROM intel4coro/base-notebook:22.04-iron

# Define environment variables
ENV MY_ROS_WS=/home/${NB_USER}/my-ros-workspace

# Change working directory (similar to command "cd")
WORKDIR ${MY_ROS_WS}

# Run bash command
RUN mkdir examples
RUN pip install vcs catkin_tools

# Run bash commands required root permission
USER root
RUN apt update && apt install nano vim
USER ${NB_USER}

# Copy files from your git repo
COPY --chown=${NB_USER}:users . ${MY_ROS_WS}/my-repo-name

# Override the entrypoint to add startup scripts.
# Note: Do not forget to add `exec "$@"` at the end of your entrypoint.
COPY --chown=${NB_USER}:users entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
```

## Development

The config of running the docker image on your machine locally is specify in [docker-compose.yml](./docker-compose.yml).

> Note: The configs in [docker-compose.yml](./docker-compose.yml) will not take effect in the Binderhub.

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

#### Enable nvidia GPU and display on local machine

To display GUI applications on your host machine instead of a Xpra virtual display. uncomment the following configs in [docker-compose.yml](./docker-compose.yml)

```docker-compose
    #   - /tmp/.X11-unix:/tmp/.X11-unix:rw
    # environment:
    #   - DISPLAY
    #   - NVIDIA_DRIVER_CAPABILITIES=all
    # deploy:
    #   resources:
    #     reservations:
    #       devices:
    #         - driver: nvidia
    #           count: all
    #           capabilities: [gpu]
```

and run `docker compose up` with X-forwarding:

```bash
xhost +local:docker && \
docker compose up && \
xhost -local:docker
```

## License

Copyright 2023 IntEL4CoRo\<intel4coro@uni-bremen.de\>

This repository is released under the Apache License 2.0, see [LICENSE](./LICENSE).  
Unless attributed otherwise, everything in this repository is under the Apache License 2.0.

### Acknowledgements

This Docker image is based on [jupyter/docker-stacks](https://github.com/jupyter/docker-stacks), licensed under the [BSD License](https://github.com/jupyter/docker-stacks/blob/main/LICENSE.md).

Gazebo example referneces [Tiryoh/docker-ros2-desktop-vnc](https://github.com/fcwu/docker-ubuntu-vnc-desktop), licensed under the [Apache License 2.0](https://github.com/Tiryoh/docker-ros2-desktop-vnc/blob/master/LICENSE).
