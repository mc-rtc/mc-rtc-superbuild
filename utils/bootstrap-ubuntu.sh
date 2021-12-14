#!/usr/bin/env bash

if [ $UID -eq 0 ]
then
  SUDO=''
else
  SUDO='sudo'
fi

${SUDO} apt-get update
${SUDO} apt-get install -y wget apt-transport-https gnupg lsb-release build-essential gfortran curl git

wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | ${SUDO} tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ $(lsb_release -sc) main" | ${SUDO} tee /etc/apt/sources.list.d/kitware.list >/dev/null
${SUDO} apt-get update
${SUDO} apt-get upgrade -y cmake cmake-curses-gui
