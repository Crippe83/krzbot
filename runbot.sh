#!/bin/bash
(($(ps auxw|grep [kr]zbot|wc -l) > 0 )) && exit
cd /home/pi/krzbot && /bin/bash krzbot.sh &
