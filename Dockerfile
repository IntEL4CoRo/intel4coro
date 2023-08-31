FROM jupyter/base-notebook:ubuntu-20.04 AS BASE_NOTEBOOK

FROM tswetnam/xpra:cudagl-20.04

ENV SHELL=/bin/bash
ENV DISPLAY=:100
ENV NB_USER=user

USER root
RUN deluser ${NB_USER} sudo

COPY --from=BASE_NOTEBOOK --chown=${NB_USER}:users /usr/local/bin/. /usr/local/bin/

# Install ROS
# ARG ROS_PKG=ros-base
ARG ROS_PKG=desktop-full
LABEL version="ROS-noetic-${ROS_PKG}"
ENV ROS_DISTRO=noetic
ENV ROS_PATH=/opt/ros/${ROS_DISTRO}
ENV ROS_ROOT=${ROS_PATH}/share/ros

RUN rm /etc/apt/sources.list.d/*
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -
RUN apt update -q && apt install -y \
      ros-${ROS_DISTRO}-${ROS_PKG} \
      ros-${ROS_DISTRO}-tf2-tools \
      vim \
      net-tools\
      build-essential \
      lsb-release \
  && apt clean \
  && echo "source ${ROS_PATH}/setup.bash" >> /root/.bashrc \
  && echo "source ${ROS_PATH}/setup.bash" >> /home/${NB_USER}/.bashrc

USER ${NB_USER}
# Update Conda base to python 3.10
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-py310_22.11.1-1-Linux-x86_64.sh -O ~/miniconda.sh \
    && /bin/bash ~/miniconda.sh -u -b -p /opt/conda \
    && rm miniconda.sh

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
  rosdep \
  rosinstall \
  rosinstall-generator \
  rosdistro \
  rosdep \
  && pip cache purge

# Initiate an empty workspace
ENV IAI_WS=/home/${NB_USER}/workspace/ros

RUN mkdir -p ${IAI_WS}/src
WORKDIR ${IAI_WS}/src/
RUN git clone https://github.com/IntEL4CoRo/pycram.git -b binder \
  && vcs import --input pycram/binder/pycram-http.rosinstall --recursive

RUN cd pycram \
  && git submodule update --init \
  && cd src/neem_interface_python \
  && git clone https://github.com/benjaminalt/neem-interface.git src/neem-interface

RUN pip install --requirement ${IAI_WS}/src/pycram/requirements.txt --user \
  && pip install --requirement ${IAI_WS}/src/pycram/src/neem_interface_python/requirements.txt --user \
  && pip cache purge

# Build pycram workspace
WORKDIR  ${IAI_WS}
USER root
RUN rosdep init \
  && rosdep update \
  && rosdep install -y --ignore-src --from-paths ./ -r \
  && rosdep fix-permissions
USER ${NB_USER}
RUN catkin config --extend ${ROS_PATH}
RUN catkin build
# Install xpra extension
COPY --chown=${NB_USER}:users jupyter-xprahtml5-proxy /home/${NB_USER}/jupyter-xprahtml5-proxy
RUN pip install -e /home/${NB_USER}/jupyter-xprahtml5-proxy

EXPOSE 8888
USER ${NB_USER}
WORKDIR /home/${NB_USER}
COPY --chown=${NB_USER}:users entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
CMD [ "start-notebook.sh" ]