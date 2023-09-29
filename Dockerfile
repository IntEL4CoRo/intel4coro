FROM jupyter/minimal-notebook:ubuntu-20.04

# --- Define Environment Variables--- #
# ARG ROS_PKG=ros-base
ARG ROS_PKG=desktop-full
LABEL version="ROS-noetic-${ROS_PKG}"
ENV ROS_DISTRO=noetic
ENV ROS_PATH=/opt/ros/${ROS_DISTRO}
ENV ROS_ROOT=${ROS_PATH}/share/ros
ENV ROS_WS=/home/${NB_USER}/workspace/ros
ENV DISPLAY=:100

# --- Install basic tools --- #
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

# --- Install Oh-my-bash --- #
USER ${NB_USER}
RUN bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended
COPY --chown=${NB_USER}:users ./bashrc.sh /home/${NB_USER}/.bashrc

# --- Install ROS noetic --- #
USER root
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -
RUN apt update -q && apt install -y \
      ros-${ROS_DISTRO}-${ROS_PKG} \
      ros-${ROS_DISTRO}-tf2-tools \
  && apt clean \
  && echo "source ${ROS_PATH}/setup.bash" >> /root/.bashrc \
  && echo "source ${ROS_PATH}/setup.bash" >> /home/${NB_USER}/.bashrc

# --- Install XPRA and GUI tools --- #
RUN wget -O - https://xpra.org/gpg.asc | apt-key add - && \
    echo "deb https://xpra.org/ focal main" > /etc/apt/sources.list.d/xpra.list
RUN apt update && apt install -y \
    xpra \
    gdm3 \
    nautilus \
    gnome-shell \
    gnome-session \
    gnome-terminal \
    libqt5x11extras5 \
    xvfb

USER ${NB_USER}
# --- Install python packages --- #
SHELL ["conda", "run", "-n", "base", "/bin/bash", "-c"]
RUN pip install \
    autobahn \
    catkin-tools \
    cbor2 \
    cryptography==38.0.4 \
    empy \
    gnupg \
    ipywidgets \
    jupyterlab==3.6.5 \
    jupyter-resource-usage \
    jupyter-offlinenotebook \
    jupyter-server-proxy \
    jupyterlab-git \
    pymongo \
    Pillow \
    pycryptodomex \
    pyyaml==5.3.1 \
    rosdep \
    rosinstall \
    rosinstall-generator \
    rosdistro \
    simplejpeg \
    twisted \
    vcstool \
    wstool && \
    pip cache purge

# --- Install jupyterlab extensions --- #
COPY --chown=${NB_USER}:users jupyter-xprahtml5-proxy /home/${NB_USER}/.jupyter-xprahtml5-proxy
RUN pip install -e /home/${NB_USER}/.jupyter-xprahtml5-proxy
RUN pip install https://raw.githubusercontent.com/yxzhan/jlab-enhanced-cell-toolbar/main/dist/jlab-enhanced-cell-toolbar-4.0.0.tar.gz

# --- Create a ROS workspace with Robot Web Tools --- #
RUN mkdir -p ${ROS_WS}/src
WORKDIR ${ROS_WS}
USER root
RUN rosdep init
USER ${NB_USER}
RUN catkin init && \
    cd src && \
    wstool init && \
    wstool merge https://raw.githubusercontent.com/yxzhan/rvizweb/master/.rosinstall && \
    wstool update && \
    catkin config --extend ${ROS_PATH} && \
    rosdep update && \
    pip install https://raw.githubusercontent.com/yxzhan/jupyterlab-rviz/master/dist/jupyterlab_rviz-0.2.8.tar.gz

USER root
RUN rosdep install -y --ignore-src --from-paths ./ -r

USER ${NB_USER}
RUN catkin build && \
    echo "source ${ROS_WS}/devel/setup.bash" >> /home/${NB_USER}/.bashrc

# --- Install Gazebo web client --- #
# WORKDIR /home/${NB_USER}
# USER root
# RUN apt install -y libjansson-dev libboost-dev imagemagick libtinyxml-dev mercurial
# USER ${NB_USER}
# RUN mamba init && \
#     mamba create -n gzweb nodejs==11.6.0 && \
#     mamba && \
#     git clone https://github.com/osrf/gzweb -b gzweb_1.4.1 && \
#     cd gzweb && \
#     source /usr/share/gazebo/setup.sh && \
#     npm run deploy --- -m

USER ${NB_USER}
WORKDIR /home/${NB_USER}
# --- Appy JupyterLab Settings --- #
COPY --chown=${NB_USER}:users ./jupyter-settings.json /opt/conda/share/jupyter/lab/settings/overrides.json

# --- Entrypoint --- #
COPY --chown=${NB_USER}:users entrypoint.sh /
COPY --chown=${NB_USER}:users webapps.json ${ROS_WS}/src/rvizweb/webapps/app.json
COPY --chown=${NB_USER}:users xpra-logo.svg ${ROS_WS}/src/rvizweb/webapps/xpra-logo.svg
ENTRYPOINT ["/entrypoint.sh"]
CMD [ "start-notebook.sh" ]