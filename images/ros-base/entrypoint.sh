#!/bin/bash
source ${HOME}/workspace/ros/devel/setup.bash

roscore &
roslaunch --wait rvizweb rvizweb.launch &
roslaunch --wait rosboard rosboard.launch &
xvfb-run exec "$@"
