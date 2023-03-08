#!/bin/bash

## This is the entry point for the Docker image.
## Everything in here is executed on boot of the Docker container.
## When this script ends, the container dies.

source /home/workspace/ros/devel/setup.bash

echo "Booting ROSCORE..."
roscore
echo "ROSCORE already running. Going to sleep..."
sleep infinity
