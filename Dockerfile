FROM tswetnam/xpra:cudagl-20.04
# ARG ROS_PKG=ros-base
ARG ROS_PKG=desktop-full
LABEL version="ROS-noetic-${ROS_PKG}"
ENV SHELL=/bin/bash
ENV DISPLAY=:0
ENV NB_USER=user
# ENV PATH=/home/${NB_USER}/.local/bin:$PATH

# Install ROS
ENV ROS_DISTRO=noetic
ENV ROS_PATH=/opt/ros/${ROS_DISTRO}
ENV ROS_ROOT=${ROS_PATH}/share/ros

USER root
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
  && echo "source ${ROS_PATH}/setup.bash" >> /home/user/.bashrc

USER ${NB_USER}
# Update Conda base to python 3.10
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-py310_22.11.1-1-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -u -b -p /opt/conda
# Install python packages
# RUN conda create -n iai python=3.10.6 \
#  && echo "conda activate iai" >> /home/${NB_USER}/.bashrc
# SHELL ["conda", "run", "-n", "iai", "/bin/bash", "-c"]
SHELL ["conda", "run", "-n", "base", "/bin/bash", "-c"]
# RUN conda install python==3.10.6
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

RUN pip install git+https://github.com/FZJ-JSC/jupyter-xprahtml5-proxy.git
EXPOSE 8888

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

WORKDIR ${IAI_WS}/src/pycram
COPY --chown=${NB_USER}:users entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
USER root
RUN ls -la /tmp
RUN chmod 1777 /tmp/.X11-unix
USER ${NB_USER}