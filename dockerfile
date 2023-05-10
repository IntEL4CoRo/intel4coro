FROM jupyter/minimal-notebook:ubuntu-20.04
# FROM pandoc/core:edge-ubuntu

USER root
RUN wget -O /pandoc.deb https://github.com/jgm/pandoc/releases/download/3.1.2/pandoc-3.1.2-1-amd64.deb
RUN dpkg -i /pandoc.deb

USER $NB_USER
RUN pip install -U jupyter-book pyyaml jupyter-archive

RUN git clone https://github.com/yxzhan/docker-stacks.git -b textbook ./textbook

WORKDIR $HOME/textbook

# ENTRYPOINT  ["/bin/bash"]
