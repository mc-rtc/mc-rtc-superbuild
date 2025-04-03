set(ROS_DISTRO kinetic)
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

function(mc_rtc_extra_steps)
  if(BUILD_BENCHMARKS)
    AddProject(
      google-benchmark
      GITHUB google/benchmark
      CMAKE_ARGS -DBENCHMARK_ENABLE_GTEST_TESTS:BOOL=OFF SKIP_TEST
    )
  endif()
endfunction()
