set(MC_LOG_UI_PYTHON_EXECUTABLE python3)
set(APT_HAS_PYTHON2_PACKAGES OFF)
set(ROS_IS_ROS2 ON)
set(ROS_DISTRO humble)
set(ROS_WORKSPACE_INSTALL_PYTHON_DESTINATION "lib/python3.10/site-packages")
set(APT_DEPENDENCIES
    curl
    wget
    cmake
    build-essential
    gfortran
    doxygen
    cython3
    python3-nose
    python3-pytest
    python3-numpy
    python3-coverage
    python3-setuptools
    python3-pip
    libeigen3-dev
    doxygen
    doxygen-latex
    libboost-all-dev
    libtinyxml2-dev
    libgeos++-dev
    libnanomsg-dev
    libyaml-cpp-dev
    libltdl-dev
    libqwt-qt5-dev
    python3-matplotlib
    python3-pyqt5
    libspdlog-dev
    ninja-build
    python-is-python3
    libnotify-dev
    python3-git
)
if(BUILD_BENCHMARKS)
  list(APPEND APT_DEPENDENCIES libbenchmark-dev)
endif()
