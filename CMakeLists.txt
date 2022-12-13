cmake_minimum_required(VERSION 3.20)

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

if(WITH_ROS_SUPPORT)
  CreateCatkinWorkspace(ID data_ws DIR "catkin_data_ws" CATKIN_MAKE)
  CreateCatkinWorkspace(ID mc_rtc_ws DIR "catkin_ws" CATKIN_BUILD)
endif()

AddProject(ndcurves
  GITHUB loco-3d/ndcurves
  GIT_TAG v1.1.5
  CMAKE_ARGS -DBUILD_PYTHON_INTERFACE:BOOL=OFF
  SKIP_TEST
)

AddProject(state-observation
  GITHUB jrl-umi3218/state-observation
  GIT_TAG origin/master
  CMAKE_ARGS -DBUILD_STATE_OBSERVATION_TOOLS:BOOL=OFF
)

if(PYTHON_BINDING)
  AddProject(Eigen3ToPython
    GITHUB jrl-umi3218/Eigen3ToPython
    GIT_TAG origin/master
  )
  list(APPEND SpaceVecAlg_DEPENDS Eigen3ToPython)
endif()

AddProject(SpaceVecAlg
  GITHUB jrl-umi3218/SpaceVecAlg
  GIT_TAG origin/master
  DEPENDS ${SpaceVecAlg_DEPENDS}
)

AddProject(sch-core
  GITHUB jrl-umi3218/sch-core
  GIT_TAG origin/master
  CMAKE_ARGS -DCMAKE_CXX_STANDARD=11
)

if(PYTHON_BINDING)
  AddProject(sch-core-python
    GITHUB jrl-umi3218/sch-core-python
    GIT_TAG origin/master
    DEPENDS sch-core SpaceVecAlg
  )
endif()

AddProject(RBDyn
  GITHUB jrl-umi3218/RBDyn
  GIT_TAG origin/master
  DEPENDS SpaceVecAlg
)

if(EMSCRIPTEN)
  set(USE_F2C_ARGS CMAKE_ARGS "-DUSE_F2C:BOOL=ON" "-DCMAKE_C_STANDARD_INCLUDE_DIRECTORIES=${CMAKE_INSTALL_PREFIX}/include")
else()
  set(USE_F2C_ARGS "")
endif()

AddProject(eigen-qld
  GITHUB jrl-umi3218/eigen-qld
  GIT_TAG origin/master
  NO_NINJA
  ${USE_F2C_ARGS}
)

AddProject(eigen-quadprog
  GITHUB jrl-umi3218/eigen-quadprog
  GIT_TAG origin/master
  NO_NINJA
  ${USE_F2C_ARGS}
)

if(WITH_LSSOL)
  AddProject(eigen-lssol
    GITE multi-contact/eigen-lssol
    GIT_TAG origin/master
    NO_NINJA
    ${USE_F2C_ARGS}
  )
endif()

set(Tasks_DEPENDS RBDyn eigen-qld sch-core)
if(WITH_LSSOL)
  list(APPEND Tasks_DEPENDS eigen-lssol)
endif()
if(PYTHON_BINDING)
  list(APPEND Tasks_DEPENDS sch-core-python)
endif()
AddProject(Tasks
  GITHUB jrl-umi3218/Tasks
  GIT_TAG origin/master
  DEPENDS ${Tasks_DEPENDS}
)

AddCatkinProject(mc_rtc_data
  GITHUB jrl-umi3218/mc_rtc_data
  GIT_TAG origin/master
  WORKSPACE data_ws
)

if(WITH_ROS_SUPPORT)
  AddCatkinProject(mc_rtc_msgs
    GITHUB jrl-umi3218/mc_rtc_msgs
    GIT_TAG origin/master
    WORKSPACE data_ws
  )
  list(APPEND mc_rtc_DEPENDS mc_rtc_msgs)
endif()

list(APPEND mc_rtc_DEPENDS Tasks mc_rtc_data ndcurves state-observation eigen-quadprog)
if(TARGET spdlog)
  list(APPEND mc_rtc_DEPENDS spdlog)
endif()
if(NOT DEFINED MC_LOG_UI_PYTHON_EXECUTABLE)
  set(MC_LOG_UI_PYTHON_EXECUTABLE ${MC_RTC_SUPERBUILD_DEFAULT_PYTHON})
endif()
if(WITH_ROS_SUPPORT)
  set(MC_RTC_ROS_OPTION "-DDISABLE_ROS=OFF")
else()
  set(MC_RTC_ROS_OPTION "-DDISABLE_ROS=ON")
endif()
if(EMSCRIPTEN)
  set(MC_RTC_EXTRA_OPTIONS -DMC_RTC_BUILD_STATIC=ON -DMC_RTC_DISABLE_NETWORK=ON -DMC_RTC_DISABLE_STACKTRACE=ON -DJVRC_DESCRIPTION_PATH=/assets/jvrc_description -DMC_ENV_DESCRIPTION_PATH=/assets/mc_env_description -DMC_INT_OBJ_DESCRIPTION_PATH=/assets/mc_int_obj_description)
else()
  set(MC_RTC_EXTRA_OPTIONS)
endif()
AddProject(mc_rtc
  GITHUB jrl-umi3218/mc_rtc
  GIT_TAG origin/master
  CMAKE_ARGS -DMC_LOG_UI_PYTHON_EXECUTABLE=${MC_LOG_UI_PYTHON_EXECUTABLE} ${MC_RTC_ROS_OPTION} ${MC_RTC_EXTRA_OPTIONS}
  DEPENDS ${mc_rtc_DEPENDS}
)

if(WITH_ROS_SUPPORT)
  AddCatkinProject(mc_rtc_ros
    GITHUB jrl-umi3218/mc_rtc_ros
    GIT_TAG origin/master
    WORKSPACE mc_rtc_ws
    DEPENDS mc_rtc
  )
endif()

add_subdirectory(robots)

file(GLOB extension_dirs CONFIGURE_DEPENDS "extensions/*")
foreach(extension_dir ${extension_dirs})
  if(EXISTS "${extension_dir}/CMakeLists.txt")
    add_subdirectory(${extension_dir})
  endif()
endforeach()

### Personal projects can go here although that is not recommended
### PERSONAL_PROJECTS

### No more personal projects past this point

FinalizeCatkinWorkspaces()

message("
mc-rtc-superbuild is now ready, the following special targets are available:
- clone: clone all projects into their location
- update: update all the projects at once
- uninstall: uninstall all the project at once

You can also use the [COMMAND]-[NAME] form to update particular projects

Or use your regular build command to build all projects
")

set(FINAL_MESSAGE
"
Source will be cloned in ${SOURCE_DESTINATION}

Please add the following lines to your .bashrc/.zshrc file:

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
export ROS_PARALLEL_JOBS=$ENV{ROS_PARALLEL_JOBS}
source ${DIR}/devel/setup.bash

Please replace setup.bash with setup.zsh in that last line if you are using zsh")
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
