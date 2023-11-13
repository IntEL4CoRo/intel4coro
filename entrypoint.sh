#!/bin/bash
source ${ROS_PATH}/setup.bash

cp -R /opt/ros/${ROS_DISTRO}/share/gazebo_plugins/worlds /home/jovyan/gazebo_worlds_demo

exec "$@"