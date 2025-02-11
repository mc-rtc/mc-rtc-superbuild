if(${CMAKE_VERSION} VERSION_LESS 3.20)
  set(message "CMake >= 3.20 is required for mc-rtc-superbuild")
  if(UNIX)
    if(APPLE)
      set(SCRIPT_SUFFIX macos)
    else()
      set(SCRIPT_SUFFIX linux)
    endif()
    set(message "${message}\nYou can run:\n${CMAKE_SOURCE_DIR}/utils/bootstrap-${SCRIPT_SUFFIX}.sh\nto prepare your system for mc-rtc-superbuild")
  else()
    set(message "${message}\nYou can download a recent version of CMake from https://cmake.org/download/")
  endif()
  message(FATAL_ERROR ${message})
endif()
cmake_minimum_required(VERSION 3.20)

if(${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_BINARY_DIR})
  message(FATAL_ERROR "Do not run cmake inside mc-rtc-superbuild folder, it will break.
  Please remove CMakeCache.txt and the CMakeFiles folder that were just created")
endif()


project(mc_rtc_superbuild LANGUAGES C CXX)
include(CTest)
enable_testing()

find_program(CCACHE_PROGRAM ccache)
if (CCACHE_PROGRAM)
    message(NOTICE "Selected CCache: ${CCACHE_PROGRAM}")
  # get_filename_component(PARENT_DIR ${PROJECT_SOURCE_DIR} DIRECTORY)
  # use cmake_path instead
message(STATUS "PROJECT_SOURCE_DIR: ${PROJECT_SOURCE_DIR}")
  cmake_path(GET PROJECT_SOURCE_DIR PARENT_PATH PARENT_DIR)
  message(STATUS "PARENT_DIR: ${PARENT_DIR}")
    set(ccacheEnv
            CCACHE_BASEDIR=${PARENT_DIR}
            # locale and umask are important for docker containers
            # no_hash_dir useful?
            CCACHE_SLOPPINESS="umask,locale,no_hash_dir,pch_defines,file_macro,include_file_ctime"
            CCACHE_NOHASHDIR=true
    )
    set(CMAKE_C_COMPILER_LAUNCHER ${CMAKE_COMMAND} -E env ${ccacheEnv} ${CCACHE_PROGRAM})
    set(CMAKE_CXX_COMPILER_LAUNCHER ${CMAKE_COMMAND} -E env ${ccacheEnv} ${CCACHE_PROGRAM})
endif ()

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES AND NOT ENV{CMAKE_BUILD_TYPE})
  message(STATUS "Setting default build type to RelWithDebInfo as none was provided")
  set(CMAKE_BUILD_TYPE "RelWithDebInfo" CACHE STRING "Choose the type of a build" FORCE)
endif()

if(EMSCRIPTEN)
  if(NOT DEFINED ENV{EMSDK})
    message(FATAL_ERROR "EMSDK not present in environment")
  endif()

  set(CMAKE_INSTALL_PREFIX "$ENV{EMSDK}/upstream/emscripten/system" CACHE PATH "" FORCE)
endif()

include(cmake/project.cmake)

if(APPLE)
  include(cmake/macos-dependencies.cmake)
endif()

if(WIN32)
  include(cmake/win32-dependencies.cmake)
endif()

if(EMSCRIPTEN)
  include(cmake/emscripten-dependencies.cmake)
endif()

if(UNIX AND NOT APPLE AND NOT EMSCRIPTEN)
  include(cmake/linux-dependencies.cmake)
endif()

include(mc_rtc.cmake)

add_subdirectory(robots)

set_property(GLOBAL PROPERTY ADDED_EXTENSIONS)

add_subdirectory(extensions)

### Personal projects can go here although that is not recommended
### PERSONAL_PROJECTS

### No more personal projects past this point

message("
mc-rtc-superbuild is now ready, the following special targets are available:
- clone: clone all projects into their location
- update: update all the projects at once
- uninstall: uninstall all the project at once

You can also use the [COMMAND]-[NAME] form to update particular projects

Or use your regular build command to build all projects
")

set(RC_FILE ".bashrc")
set(RC_EXT ".bash")
if("$ENV{SHELL}" STREQUAL "/usr/bin/zsh" OR "$ENV{SHELL}" STREQUAL "/bin/zsh")
  set(RC_FILE ".zshrc")
  set(RC_EXT ".zsh")
endif()

set(FINAL_MESSAGE
"
Source will be cloned in ${SOURCE_DESTINATION}

Please add the following lines to your ${RC_FILE} file:

export PATH=${CMAKE_INSTALL_PREFIX}/bin:$PATH
export PKG_CONFIG_PATH=${CMAKE_INSTALL_PREFIX}/lib/pkgconfig:$PKG_CONFIG_PATH"
)

if(APPLE)
  set(FINAL_MESSAGE "${FINAL_MESSAGE}
export DYLD_LIBRARY_PATH=${CMAKE_INSTALL_PREFIX}/lib:$DYLD_LIBRARY_PATH")
elseif(UNIX)
  set(FINAL_MESSAGE "${FINAL_MESSAGE}
export LD_LIBRARY_PATH=${CMAKE_INSTALL_PREFIX}/lib:$LD_LIBRARY_PATH")
endif()

if(MC_RTC_SUPERBUILD_DEFAULT_PYTHON AND NOT PYTHON_BINDING_USER_INSTALL)
  set(FINAL_MESSAGE "${FINAL_MESSAGE}
export PYTHONPATH=${EXTRA_PYTHONPATH}:$PYTHONPATH")
endif()

if(WITH_ROS_SUPPORT)
  get_property(ID GLOBAL PROPERTY PREVIOUS_CATKIN_WORKSPACE)
  if(NOT "${ID}" STREQUAL "")
    get_property(DIR GLOBAL PROPERTY CATKIN_WORKSPACE_${ID}_DIR)
    if(ROS_IS_ROS2)
      set(ROS_SETUP_PATH "${DIR}/install/setup${RC_EXT}")
    else()
      set(ROS_SETUP_PATH "${DIR}/devel/setup${RC_EXT}")
    endif()
    set(FINAL_MESSAGE "${FINAL_MESSAGE}
export ROS_PARALLEL_JOBS=\"$ENV{ROS_PARALLEL_JOBS}\"
source ${ROS_SETUP_PATH}
")
  endif()
endif()

if(WIN32)
  if(MC_RTC_SUPERBUILD_SET_ENVIRONMENT)
    set(FINAL_MESSAGE "${FINAL_MESSAGE}

This has already been set in your environment. Please open a new shell for the change to take effect.")
  endif()
endif()

message("${FINAL_MESSAGE}")

install(CODE "message(\"\")")
install(CODE "message(\"Installation done\")")
install(CODE "message(\"\")")
install(CODE "message(\"${FINAL_MESSAGE}\")")
