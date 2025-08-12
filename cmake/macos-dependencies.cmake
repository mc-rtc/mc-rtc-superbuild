set(BREW_DEPENDENCIES
    coreutils
    pkg-config
    gnu-sed
    wget
    python
    cmake
    doxygen
    libtool
    tinyxml2
    geos
    boost
    eigen
    nanomsg
    yaml-cpp
    qt
    qwt
    pyqt
    gcc
    spdlog
    ninja
    git
    libnotify
)
if(BUILD_BENCHMARKS)
  list(APPEND BREW_DEPENDENCIES google-benchmark)
endif()
set(PIP_DEPENDENCIES coverage nose pytest matplotlib cython numpy)
if(WITH_ROS_SUPPORT AND NOT DEFINED ENV{ROS_DISTRO})
  message(
    FATAL_ERROR
      "ROS support is enabled but ROS_DISTRO is not set. Please source the setup before continuing or disable ROS support."
  )
endif()

if(INSTALL_SYSTEM_DEPENDENCIES)
  find_program(BREW brew)
  if(NOT BREW)
    execute_process(
      COMMAND
        /bin/bash -c /bin/bash -c
        "\"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    )
    find_program(BREW brew)
    if(NOT BREW)
      message(
        FATAL_ERROR
          "Installation of Homebrew failed, check the output above or install Homebrew yourself: https://brew.sh/"
      )
    endif()
  endif()
  execute_process(COMMAND ${BREW} update)
  execute_process(COMMAND ${BREW} pin cmake)
  execute_process(COMMAND ${BREW} install ${BREW_DEPENDENCIES})
  execute_process(COMMAND ${BREW} upgrade ${BREW_DEPENDENCIES})
  execute_process(COMMAND ${BREW} unpin cmake)
  # Temporary fix for the macOS setup on github actions
  execute_process(COMMAND brew unlink gfortran)
  execute_process(COMMAND brew link gfortran)
  if(PYTHON_BINDING)
    if(PYTHON_BINDING_BUILD_PYTHON2_AND_PYTHON3 OR PYTHON_BINDING_FORCE_PYTHON2)
      message(
        FATAL_ERROR
          "Python 2 is not supported on macOS, disable PYTHON_BINDING or enable Python 3 bindings only"
      )
    endif()
    execute_process(
      COMMAND sudo ${MC_RTC_SUPERBUILD_DEFAULT_PYTHON} -m pip install
              ${PIP_DEPENDENCIES}
    )
  endif()
endif()
