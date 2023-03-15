#!/bin/bash

## This is the entry point for the Docker image.
## Everything in here is executed on boot of the Docker container.
## When this script ends, the container dies.

source /home/workspace/ros/devel/setup.bash

echo "Launching cram_projection_demos household_pr2.launch "
roslaunch cram_projection_demos household_pr2.launch &

sleep 2
echo "Launching rvizweb"
roslaunch rvizweb rvizweb.launch &

# One time Development env Setup
if [ ! -f "/root/.jupyter/jupyter_notebook_config.py" ]; then
    echo "Setup Dev Env"
    rm -rf /home/workspace/ros/build/rvizweb/www/bower_components/ros-rviz
    ln -s /home/development/polymer-ros-rviz /home/workspace/ros/build/rvizweb/www/bower_components/ros-rviz
    # Disable jupyterlab authentication
    mkdir /root/.jupyter
    jupyter notebook --generate-config
    echo "c.NotebookApp.token = ''" >> /root/.jupyter/jupyter_notebook_config.py
    # Fix the missing material file problem
    sed -i '3d' /home/workspace/ros/src/cram/cram_demos/cram_projection_demos/resource/household/bowl.obj
    sed -i '3d' /home/workspace/ros/src/cram/cram_demos/cram_projection_demos/resource/household/cup.obj
fi

sleep 2
echo ""
echo "Start jupyterlab server with xvfb-run"
# jupyter-lab --allow-root --no-browser --port 8888 --ip=0.0.0.0
xvfb-run jupyter-lab --allow-root --no-browser --port 8888 --ip=0.0.0.0