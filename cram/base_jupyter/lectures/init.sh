#!/bin/bash

## This is the entry point for the Docker image.
## Everything in here is executed on boot of the Docker container.
## When this script ends, the container dies.

source ${HOME}/workspace/ros/devel/setup.bash

echo "Launching Roscore"
roscore &

echo "Launching cram_projection_demos household_pr2.launch "
roslaunch --wait cram_projection_demos household_pr2.launch &

echo "Launching rvizweb"
roslaunch --wait rvizweb rvizweb.launch & 

sleep 2
jupyter lab workspaces import /home/jovyan/lectures/workspace.json

xvfb-run exec "$@"
