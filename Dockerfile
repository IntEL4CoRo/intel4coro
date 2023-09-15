FROM jupyter/minimal-notebook:ubuntu-20.04

# Install ROS
# ARG ROS_PKG=ros-base
ARG ROS_PKG=desktop-full
LABEL version="ROS-noetic-${ROS_PKG}"
ENV ROS_DISTRO=noetic
ENV ROS_PATH=/opt/ros/${ROS_DISTRO}
ENV ROS_ROOT=${ROS_PATH}/share/ros
ENV DISPLAY=:100

# Install basic tools
USER root
RUN  apt update -q && apt install -y \
      git \
      vim \
      curl \
      gnupg2 \
      net-tools\
      ca-certificates \
      apt-transport-https \
      build-essential \
      lsb-release
# Install ROS
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -
RUN apt update -q && apt install -y \
      ros-${ROS_DISTRO}-${ROS_PKG} \
      ros-${ROS_DISTRO}-tf2-tools \
  && apt clean \
  && echo "source ${ROS_PATH}/setup.bash" >> /root/.bashrc \
  && echo "source ${ROS_PATH}/setup.bash" >> /home/${NB_USER}/.bashrc
# Install XPRA
RUN wget -O - https://xpra.org/gpg.asc | apt-key add - && \
    echo "deb https://xpra.org/ focal main" > /etc/apt/sources.list.d/xpra.list

RUN apt update && apt install -y \
    xpra \
    gdm3 \
    glances \
    firefox \
    nautilus \
    glmark2 \
    gnome-shell \
    gnome-session \
    gnome-terminal \
    libqt5x11extras5 \
    xvfb

USER ${NB_USER}

# Install python packages
SHELL ["conda", "run", "-n", "base", "/bin/bash", "-c"]
RUN pip install \
  empy \
  jupyterlab==3.6.5 \
  jupyterhub==3.0.0 \
  ipywidgets \
  jupyter-resource-usage \
  jupyter-offlinenotebook \
  jupyterlab-git \
  jupyter-server-proxy \
  catkin-tools \
  vcstool \
  twisted \
  pyyaml==5.3.1 \
  autobahn \
  rosdep \
  rosinstall \
  rosinstall-generator \
  rosdistro \
  rosdep \
  && pip cache purge

# Install xpra extension
COPY --chown=${NB_USER}:users jupyter-xprahtml5-proxy /home/${NB_USER}/.jupyter-xprahtml5-proxy
RUN pip install -e /home/${NB_USER}/.jupyter-xprahtml5-proxy

RUN pip install https://raw.githubusercontent.com/yxzhan/jlab-enhanced-cell-toolbar/main/dist/jlab-enhanced-cell-toolbar-4.0.0.tar.gz

# Initiate an empty workspace
ENV ROS_WS=/home/${NB_USER}/workspace/ros
RUN mkdir -p ${ROS_WS}/src
WORKDIR ${ROS_WS}

USER root
RUN rosdep init

USER ${NB_USER}
RUN rosdep update

USER root
RUN rosdep install -y --ignore-src --from-paths ./ -r

USER ${NB_USER}
RUN catkin config --extend ${ROS_PATH}
RUN catkin build

USER ${NB_USER}
WORKDIR /home/${NB_USER}
COPY --chown=${NB_USER}:users entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
CMD [ "start-notebook.sh" ]