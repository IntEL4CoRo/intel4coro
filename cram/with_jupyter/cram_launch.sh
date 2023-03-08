#!/bin/bash
echo "start cram "
source /home/workspace/ros/devel/setup.bash
roslaunch cram_pick_place_tutorial world.launch &
# export THIS_IP=$(ifconfig 'docker0' | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')
sleep 2
echo "start launch cram"
echo ""
xvfb-run -a jupyter-lab --allow-root --no-browser --port 8888 --ip=$THIS_IP #if display 99 inuse -a flag use another display
echo "stop launch cram and shell"
#cp -r /rvizweb_ws/build/rvizweb/www/* /rvizweb_ws/install/share/rvizweb/www/
