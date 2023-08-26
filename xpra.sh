xpra start --start=rqt_graph --bind-tcp=0.0.0.0:10000 --html=on --daemon=no

export DISPLAY=:0
docker run --rm -it -p 9876:9876 tswetnam/xpra:opengl-20.04 /bin/bash

xpra start --bind-tcp=0.0.0.0:9876 --html=on --start-child=xterm --exit-with-children --daemon=no

export DISPLAY=:0
docker run --gpus all --rm -it -p 9876:9876 -e DISPLAY -e NVIDIA_DRIVER_CAPABILITIES=all  tswetnam/xpra:cudagl-20.04


xpra start --bind-tcp=0.0.0.0:9876 --html=on --start-child=xterm --exit-with-children --daemon=no

tail -f /tmp/:0.log

docker run -it -rm -p 9876:9876 tswetnam/xpra:bionic xpra start --bind-tcp=0.0.0.0:9876 --html=on --start-child=xterm --exit-with-children --daemon=no


docker run --gpus all -d -it -p 8848:8888 -v $(pwd)/data:/home/jovyan/work -e GRANT_SUDO=yes -e JUPYTER_ENABLE_LAB=yes --user root cschranz/gpu-jupyter:v1.5_cuda-11.6_ubuntu-20.04_python-only