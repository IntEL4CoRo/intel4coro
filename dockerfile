FROM jupyter/base-notebook:ubuntu-20.04
# FROM pandoc/core:edge-ubuntu

USER root
RUN wget -O /pandoc.deb https://github.com/jgm/pandoc/releases/download/3.1.2/pandoc-3.1.2-1-amd64.deb
RUN dpkg -i /pandoc.deb

RUN pip install -U jupyter-book pyyaml

WORKDIR /data

EXPOSE 8888

ENTRYPOINT  ["/bin/bash"]
