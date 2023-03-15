#!/bin/bash

## This is the entry point for the Docker image.
## Everything in here is executed on boot of the Docker container.
## When this script ends, the container dies.

source ${HOME}/workspace/ros/devel/setup.bash

echo "Launching cram_projection_demos household_pr2.launch "
roslaunch cram_projection_demos household_pr2.launch &

sleep 2
echo "Launching rvizweb"
roslaunch rvizweb rvizweb.launch config_name:=cram_projection_demos &

# One time Development env Setup
# if [ ! -f "/root/.jupyter/jupyter_notebook_config.py" ]; then
    # echo "Setup Dev Env"
    # pip install https://raw.githubusercontent.com/yxzhan/jupyterlab-rviz/master/release/jupyterlab_rviz-0.2.2.tar.gz
    # rm -rf ${HOME}/workspace/ros/build/rvizweb/www/bower_components/ros-rviz
    # ln -s /home/development/polymer-ros-rviz ${HOME}/workspace/ros/build/rvizweb/www/bower_components/ros-rviz
    # Disable jupyterlab authentication
    # mkdir /root/.jupyter
    # jupyter notebook --generate-config
    # echo "c.NotebookApp.token = ''" >> /root/.jupyter/jupyter_notebook_config.py
    # Fix the missing material file problem
# fi

sleep 2
# jupyter-lab --allow-root --no-browser --port 8888 --ip=0.0.0.0
xvfb-run jupyter-lab --no-browser --port 8888