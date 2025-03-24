set(MC_LOG_UI_PYTHON_EXECUTABLE python3)
set(APT_HAS_PYTHON2_PACKAGES OFF)
set(ROS_IS_ROS2 ON)
set(ROS_DISTRO humble)
set(ROS_WORKSPACE_INSTALL_PYTHON_DESTINATION "lib/python3.10/site-packages")
set(APT_DEPENDENCIES
  wget
  cmake
  build-essential
  gfortran
  doxygen
  cython
  cython3
  python-pip
  python3-pip
  python-nose
  python3-nose
  python-pytest
  python3-pytest
  python-numpy
  python3-numpy
  python-coverage
  python3-coverage
  python-setuptools
  python3-setuptools
  libeigen3-dev
  doxygen
  doxygen-latex
  libboost-all-dev
  libtinyxml2-dev
  libgeos++-dev
  libnanomsg-dev
  libyaml-cpp-dev
  libltdl-dev
  python-git
  python-pyqt5
  qt5-default
  libqwt-qt5-dev
  python-matplotlib
  ninja-build
  libnotify-dev
)
if(BUILD_BENCHMARKS)
  list(APPEND APT_DEPENDENCIES libbenchmark-dev)
endif()
