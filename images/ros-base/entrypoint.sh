#!/bin/bash
source ${HOME}/workspace/ros/devel/setup.bash

roscore &
roslaunch --wait rvizweb rvizweb.launch &
xvfb-run exec "$@"
