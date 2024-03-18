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
RUN apt update -q \
  && apt dist-upgrade -y \
  && apt install -y \
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
    firefox \
    gdm3 \
    nautilus \
    gnome-shell \
    gnome-session \
    gnome-terminal \
    libqt5x11extras5 \
    xvfb

# Fix xpra html5 client bug
RUN sed -i '547s/self/this/' /usr/share/xpra/www/js/Client.js
RUN rm /usr/share/xpra/www/js/Client.js.gz
RUN rm /usr/share/xpra/www/js/Client.js.br

USER ${NB_USER}
# --- Install python packages --- #
SHELL ["conda", "run", "-n", "base", "/bin/bash", "-c"]
# RUN pip install --upgrade "jupyterlab<4"\
RUN pip install \
    autobahn \
    catkin-tools \
    cbor2 \
    cryptography==38.0.4 \
    empy==3.3.4 \
    gnupg \
    ipywidgets \
    jupyterlab~=3.6.5 \
    sidecar==0.5.2 \
    jupyter-resource-usage \
    jupyter-offlinenotebook \
    jupyter-server-proxy \
    jupyterlab-git~=0.30.0 \
    jupyter-archive \
    jupyterlab_execute_time \
    jupyterlab-language-pack-de-DE \
    jupyter-ai~=1.10.0 \
    openai \
    service_identity \
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
    wstool \
&& pip cache purge

# --- Install jupyterlab extensions --- #
RUN pip install git+https://github.com/yxzhan/jupyter-xprahtml5-proxy.git
RUN pip install https://raw.githubusercontent.com/yxzhan/jupyterlab-rviz/master/dist/jupyterlab_rviz-0.3.2.tar.gz \
  https://raw.githubusercontent.com/yxzhan/extension-examples/main/cell-toolbar/dist/jupyterlab_examples_cell_toolbar-0.1.4.tar.gz

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
    catkin config --extend ${ROS_PATH}

USER root
RUN apt update && \
    rosdep update && \
    rosdep install -y --ignore-src --from-paths ./ -r && \
    rosdep fix-permissions

USER ${NB_USER}
RUN catkin build && \
    echo "source ${ROS_WS}/devel/setup.bash" >> /home/${NB_USER}/.bashrc

USER ${NB_USER}
WORKDIR /home/${NB_USER}

# --- update nodejs to version 18 for installing jupyter extensions from source --- #
RUN mamba install -y nodejs=18

# --- Copy JupyterLab UI settings files --- #
COPY --chown=${NB_USER}:users ./jupyter-settings.json /opt/conda/share/jupyter/lab/settings/overrides.json
COPY --chown=${NB_USER}:users webapps.json ${ROS_WS}/src/rvizweb/webapps/app.json
COPY --chown=${NB_USER}:users xpra-logo.svg ${ROS_WS}/src/rvizweb/webapps/xpra-logo.svg

# --- Entrypoint --- #
COPY --chown=${NB_USER}:users entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
CMD [ "start-notebook.sh" ]