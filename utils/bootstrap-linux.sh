#!/usr/bin/env bash

if [ $UID -eq 0 ]
then
  SUDO=''
else
  SUDO='sudo'
  if ! command -v sudo > /dev/null
  then
    echo "sudo not found but required to bootstrap"
    exit 1
  fi
fi

if ! command -v apt-get > /dev/null
then
  echo "apt-get not found but required to bootstrap, are you using a Debian-based distribution?"
  exit 1
fi

${SUDO} apt-get update
${SUDO} apt-get install -y wget apt-transport-https gnupg lsb-release build-essential gfortran curl git sudo cmake cmake-curses-gui python3-pip

if [[ `lsb_release -si` == "Ubuntu" ]]
then
  wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | ${SUDO} tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null
  echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ $(lsb_release -sc) main" | ${SUDO} tee /etc/apt/sources.list.d/kitware.list >/dev/null
  ${SUDO} apt-get update
  ${SUDO} apt-get upgrade -y cmake cmake-curses-gui
else
  CMAKE_VERSION="3.22.1"
  CMAKE_VERSION_FULL="${CMAKE_VERSION}-linux-$(uname -m)"
  wget -O /tmp/cmake-${CMAKE_VERSION_FULL}.sh https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION_FULL}.sh
  chmod +x /tmp/cmake-${CMAKE_VERSION_FULL}
  ${SUDO} /tmp/cmake-${CMAKE_VERSION_FULL} --skip-license --prefix=/usr --exclude-subdir
fi
