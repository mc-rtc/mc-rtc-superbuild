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
    cython3
    # python3-nose python3-pytest python3-numpy python3-coverage python3-setuptools
    # python3-pip
    libeigen3-dev
    libboost-all-dev
    libtinyxml2-dev
    libgeos++-dev
    libnanomsg-dev
    libyaml-cpp-dev
    libltdl-dev
    libqwt-qt5-dev
    # python3-matplotlib python3-pyqt5
    libspdlog-dev
    ninja-build
    # python-is-python3
    libnotify-dev
    # python3-git
)
if(BUILD_BENCHMARKS)
  list(APPEND APT_DEPENDENCIES libbenchmark-dev)
endif()
if(INSTALL_DOCUMENTATION)
  list(APPEND APT_DEPENDENCIES doxygen doxygen-latex)
endif()

function(mc_rtc_extra_steps)
  if(PYTHON_BINDING_BUILD_PYTHON2_AND_PYTHON3 OR PYTHON_BINDING_FORCE_PYTHON2)
    message(
      FATAL_ERROR
        "Python 2 is not supported on Focal, disable PYTHON_BINDING or enable Python 3 binding only"
    )
  endif()
endfunction()

AddProject(
  geos-cpp-inline
  GITHUB isri-aist/geos-cpp-inline-deb
  GIT_TAG origin/main INSTALL_PREFIX /usr SKIP_TEST NO_SOURCE_MONITOR
  APT_PACKAGES libgeos++-inline-dev
)
list(APPEND GLOBAL_DEPENDS geos-cpp-inline)

include(${CMAKE_CURRENT_LIST_DIR}/mc-rtc-mirror.cmake)
