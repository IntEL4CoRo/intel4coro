#!/bin/bash

source ${HOME}/workspace/ros/devel/setup.bash

echo "Launching Roscore"
roscore &

echo "Launching cram_projection_demos household_pr2.launch "
roslaunch --wait cram_projection_demos household_pr2.launch &

echo "Launching rvizweb"
roslaunch --wait rvizweb rvizweb.launch & 

xvfb-run exec "$@"
