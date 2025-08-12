set(MC_LOG_UI_PYTHON_EXECUTABLE python3)
set(ROS_DISTRO noetic)
set(ROS_WORKSPACE_INSTALL_PYTHON_DESTINATION "lib/python3/dist-packages")
set(APT_DEPENDENCIES
    curl
    wget
    cmake
    build-essential
    gfortran
    doxygen
    cython
    cython3
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
    qt5-default
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

function(mc_rtc_extra_steps)
  if(PYTHON_BINDING_BUILD_PYTHON2_AND_PYTHON3 OR PYTHON_BINDING_FORCE_PYTHON2)
    message(
      FATAL_ERROR
        "Python 2 is not supported on Focal, disable PYTHON_BINDING or enable Python 3 binding only"
    )
  endif()
endfunction()

include(${CMAKE_CURRENT_LIST_DIR}/mc-rtc-mirror.cmake)
