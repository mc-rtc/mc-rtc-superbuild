set(ROS_DISTRO melodic)
set(ROS_WORKSPACE_INSTALL_PYTHON_DESTINATION "lib/python2.7/dist-packages")
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

include(${CMAKE_CURRENT_LIST_DIR}/mc-rtc-mirror.cmake)

# We need spdlog >= 1.5.0 and it is not available in Bionic
AddProject(
  spdlog
  GITHUB gabime/spdlog
  GIT_TAG v1.6.1
  CMAKE_ARGS -DSPDLOG_BUILD_EXAMPLE:BOOL=OFF -DSPDLOG_BUILD_SHARED:BOOL=ON SKIP_TEST
  APT_PACKAGES libspdlog-dev
)
list(APPEND GLOBAL_DEPENDS spdlog)
