set(ROS_DISTRO melodic)
set(APT_DEPENDENCIES
  wget
  cmake
  build-essential
  gfortran
  doxygen
  cython
  cython3
  python-pip
  python-nose
  python3-nose
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
)
if(BUILD_BENCHMARKS)
  list(APPEND APT_DEPENDENCIES libbenchmark-dev)
endif()

# We need spdlog >= 1.5.0 and it is not available in Bionic
AddProject(spdlog
  GITHUB gabime/spdlog
  GIT_TAG v1.6.1
  CMAKE_ARGS -DSPDLOG_BUILD_EXAMPLE:BOOL=OFF -DSPDLOG_BUILD_SHARED:BOOL=ON
  SKIP_TEST
)
list(APPEND GLOBAL_DEPENDS spdlog)
