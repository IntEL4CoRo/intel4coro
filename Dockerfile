FROM jupyter/minimal-notebook:ubuntu-20.04

# --- Define Environment Variables--- #
# ARG ROS_PKG=ros-base
ARG ROS_PKG=desktop-full
LABEL version="ROS-noetic-${ROS_PKG}"
ENV ROS_DISTRO=noetic
ENV ROS_PATH=/opt/ros/${ROS_DISTRO}
ENV ROS_ROOT=${ROS_PATH}/share/ros
ENV ROS_WS=/home/${NB_USER}/workspace/ros

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

# --- Install VNC server and XFCE desktop environment --- #
USER root
RUN apt-get -y -qq update \
 && apt-get -y -qq install \
        dbus-x11 \
        firefox \
        xfce4 \
        xfce4-panel \
        xfce4-session \
        xfce4-settings \
        xorg \
        xubuntu-icon-theme \
        fonts-dejavu \
    # Disable the automatic screenlock since the account password is unknown
 && apt-get -y -qq remove xfce4-screensaver \
    # chown $HOME to workaround that the xorg installation creates a
    # /home/jovyan/.cache directory owned by root
    # Create /opt/install to ensure it's writable by pip
 && mkdir -p /opt/install \
 && chown -R $NB_UID:$NB_GID $HOME /opt/install \
 && rm -rf /var/lib/apt/lists/*

# Install a VNC server, either TigerVNC (default) or TurboVNC
ENV PATH=/opt/TurboVNC/bin:$PATH
RUN echo "Installing TurboVNC"; \
    # Install instructions from https://turbovnc.org/Downloads/YUM
    wget -q -O- https://packagecloud.io/dcommander/turbovnc/gpgkey | \
    gpg --dearmor >/etc/apt/trusted.gpg.d/TurboVNC.gpg; \
    wget -O /etc/apt/sources.list.d/TurboVNC.list https://raw.githubusercontent.com/TurboVNC/repo/main/TurboVNC.list; \
    apt-get -y -qq update; \
    apt-get -y -qq install \
        turbovnc \
    ; \
    rm -rf /var/lib/apt/lists/*;

USER $NB_USER
RUN conda install -y websockify
RUN pip install jupyter-remote-desktop-proxy
ENV DISPLAY=:1

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

# --- Entrypoint --- #
COPY --chown=${NB_USER}:users entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
CMD [ "start-notebook.sh" ]