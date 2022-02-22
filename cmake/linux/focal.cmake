set(MC_LOG_UI_PYTHON_EXECUTABLE python3)
set(ROS_DISTRO noetic)
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
  qt5-default
  libqwt-qt5-dev
  python3-matplotlib
  python3-pyqt5
  libspdlog-dev
  ninja-build
)
if(BUILD_BENCHMARKS)
  list(APPEND APT_DEPENDENCIES libbenchmark-dev)
endif()

function(mc_rtc_extra_steps)
  AptInstall(curl)
  find_program(PIP2 pip2)
  if(NOT PIP2)
    message(STATUS "Installing pip2 for python2")
    set(GET_PIP "${CMAKE_CURRENT_BINARY_DIR}/get-pip.py")
    execute_process(COMMAND curl https://bootstrap.pypa.io/pip/2.7/get-pip.py -o "${GET_PIP}" RESULT_VARIABLE CMD_FAILED)
    if(CMD_FAILED)
      message(FATAL_ERROR "Failed to get get-pip.py")
    endif()
    execute_process(COMMAND sudo python2 "${GET_PIP}" RESULT_VARIABLE CMD_FAILED)
    if(CMD_FAILED)
      message(FATAL_ERROR "Failed to install pip2")
    endif()
    file(REMOVE "${GET_PIP}")
  endif()
endfunction()
