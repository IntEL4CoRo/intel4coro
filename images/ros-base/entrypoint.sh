#!/bin/bash
source ${HOME}/workspace/ros/devel/setup.bash

roscore &
roslaunch --wait rvizweb rvizweb.launch &

if [ -n "$DISPLAY" ]; then
    exec "$@"
else
    xvfb-run exec "$@"
fi
