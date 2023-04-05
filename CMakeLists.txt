cmake_minimum_required(VERSION 3.20)

if(${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_BINARY_DIR})
  message(FATAL_ERROR "Do not run cmake inside mc-rtc-superbuild folder, it will break.
  Please remove CMakeCache.txt and the CMakeFiles folder that were just created")
endif()

project(mc_rtc_superbuild LANGUAGES C CXX)
include(CTest)
enable_testing()

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

function(RequireExtension FOLDER)
  if(NOT EXISTS "${PROJECT_SOURCE_DIR}/extensions/${FOLDER}")
    include(FetchContent)
    FetchContent_Declare(${FOLDER} ${ARGN} SOURCE_DIR "${PROJECT_SOURCE_DIR}/extensions/${FOLDER}")
    FetchContent_Populate(${FOLDER})
  endif()
  AddExtension(${PROJECT_SOURCE_DIR}/extensions/${FOLDER})
endfunction()

function(AddExtension FOLDER)
  if(EXISTS "${FOLDER}/required-extensions.cmake")
    include("${FOLDER}/required-extensions.cmake")
  endif()
  get_property(ADDED_EXTENSIONS GLOBAL PROPERTY ADDED_EXTENSIONS)
  if(NOT ${FOLDER} IN_LIST ADDED_EXTENSIONS)
    set_property(GLOBAL APPEND PROPERTY ADDED_EXTENSIONS ${FOLDER})
    add_subdirectory(${FOLDER})
  endif()
endfunction()

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
  execute_process(COMMAND ${MC_RTC_SUPERBUILD_DEFAULT_PYTHON} -c "from distutils import sysconfig; print(sysconfig.get_python_lib(prefix = '${CMAKE_INSTALL_PREFIX}', plat_specific = True))" RESULT_VARIABLE PYTHON_INSTALL_DIR_FOUND OUTPUT_VARIABLE PYTHON_INSTALL_DIR OUTPUT_STRIP_TRAILING_WHITESPACE)
  execute_process(COMMAND ${MC_RTC_SUPERBUILD_DEFAULT_PYTHON} -c "from distutils import sysconfig; print(sysconfig.get_python_lib(standard_lib = True, prefix = '${CMAKE_INSTALL_PREFIX}', plat_specific = True))" RESULT_VARIABLE PYTHON_INSTALL_DIR_FOUND OUTPUT_VARIABLE PYTHON_INSTALL_STANDARD_DIR OUTPUT_STRIP_TRAILING_WHITESPACE)
  set(FINAL_MESSAGE "${FINAL_MESSAGE}
export PYTHONPATH=${PYTHON_INSTALL_DIR}:${PYTHON_INSTALL_STANDARD_DIR}/dist-packages:$PYTHONPATH")
endif()

if(WITH_ROS_SUPPORT)
  get_property(ID GLOBAL PROPERTY PREVIOUS_CATKIN_WORKSPACE)
  if(NOT "${ID}" STREQUAL "")
    get_property(DIR GLOBAL PROPERTY CATKIN_WORKSPACE_${ID}_DIR)
    set(FINAL_MESSAGE "${FINAL_MESSAGE}
export ROS_PARALLEL_JOBS=\"$ENV{ROS_PARALLEL_JOBS}\"
source ${DIR}/devel/setup${RC_EXT}
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
