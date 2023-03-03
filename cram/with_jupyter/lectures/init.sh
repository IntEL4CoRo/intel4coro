#!/bin/bash

## This is the entry point for the Docker image.
## Everything in here is executed on boot of the Docker container.
## When this script ends, the container dies.

source /home/workspace/ros/devel/setup.bash

echo "Launching cram_projection_demos household_pr2.launch "
# roslaunch cram_pick_place_tutorial world.launch &
roslaunch cram_projection_demos household_pr2.launch &

sleep 2
echo "Launching rvizweb"
roslaunch rvizweb rvizweb.launch &

# export THIS_IP=$(ifconfig 'docker0' | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')
sleep 2
echo ""
echo "Start jupyterlab server with xvfb-run"
xvfb-run jupyter-lab --allow-root --no-browser --port 8888 --ip=0.0.0.0

