#!/bin/bash

## This is the entry point for the Docker image.
## Everything in here is executed on boot of the Docker container.
## When this script ends, the container dies.

source ${HOME}/workspace/ros/devel/setup.bash

echo "Launching cram_projection_demos household_pr2.launch "
roslaunch cram_projection_demos household_pr2.launch &

sleep 2
echo "Launching rvizweb"
roslaunch rvizweb rvizweb.launch &

sleep 2
echo "Start jupyterlab server with xvfb-run"
xvfb-run start-singleuser.sh
