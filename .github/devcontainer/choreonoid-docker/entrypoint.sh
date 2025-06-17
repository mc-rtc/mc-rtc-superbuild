#!/usr/bin/env bash

cdhrpsys() { 
  cd /usr/local/share/hrpsys/samples 
}

run_choreonoid() {
  cdhrpsys
  cd $1
  ./clear-omninames2.sh
  choreonoid sim_mc_udp.cnoid --start-simulation
}

help()
{
  echo "-----------------"
  echo "Welcome to choreonoid-private image for Ubuntu jammy!"
  echo "This image contains choreonoid, mc_udp, and all private robots available at AIST and LIRMM"
  echo "Do not share this image to unauthorized users"
  echo
  echo "-----------------"
  echo "To use this image:"
  echo "$ xhost +local:docker # for X11 in docker"
  echo "$ docker run --rm -it --user root --network host --env DISPLAY=$DISPLAY  --privileged -v $HOME/.Xauthority:/root/.Xauthority -v /tmp/.X11-unix:/tmp/.X11-unix choreonoid-private <command>"
  echo "where <command> is:"
  echo "    bash                            runs an interactive bash session"
  echo "    choreonoid <robot> <project>    runs a choreonoid project"
  echo "                                      ex: choreonoid RHPS1 sim_mc_upd.cnoid"
  echo "    list-robots"
}


source /usr/local/setup_mc_rtc.sh
cp /usr/local/share/hrpsys/samples/RHPS1/clear-omninames2.sh /usr/local/bin
help

case $1 in
  choreonoid)
    if [ $# -eq 3 ]; then
      run_choreonoid $2 $3
    else
      help
    fi
    ;;
  list-robots)
    echo "Available robots and projects: "
    find /usr/local/share/hrpsys/samples '*.cnoid'
    ;;
  bash)
    bash
    ;;
  *)
    ;;
esac
