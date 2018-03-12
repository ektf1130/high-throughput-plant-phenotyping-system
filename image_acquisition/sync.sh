#!/bin/bash
sshpass -p "raspberry" rsync -rtv pi@192.168.0.10:/home/pi/LiveView/ ./camera1
