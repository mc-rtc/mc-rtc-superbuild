cmake_minimum_required(VERSION 3.20)

project(mc_rtc_superbuild)
enable_testing()

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  message(STATUS "Setting default build type to RelWithDebInfo as none was provided")
  set(CMAKE_BUILD_TYPE "RelWithDebInfo" CACHE STRING "Choose the type of a build" FORCE)
endif()

include(cmake/project.cmake)
include(cmake/ros.cmake)

set(SYSTEM_HAS_SPDLOG FALSE)

if(APPLE)
  include(cmake/macos-dependencies.cmake)
endif()

if(WIN32)
  include(cmake/win32-dependencies.cmake)
endif()

if(UNIX)
  include(cmake/linux-dependencies.cmake)
endif()

if(WITH_ROS_SUPPORT)
  if(GET_SOURCE_IN_SOURCE)
    set(CATKIN_WORKSPACE_BASEDIR "${PROJECT_SOURCE_DIR}/src")
  else()
    set(CATKIN_WORKSPACE_BASEDIR "${PROJECT_BINARY_DIR}/src")
  endif()
  set(CATKIN_DATA_WORKSPACE "${CATKIN_WORKSPACE_BASEDIR}/catkin_data_ws")
  CreateCatkinWorkspace("${CATKIN_DATA_WORKSPACE}")
  set(CATKIN_WORKSPACE "${CATKIN_WORKSPACE_BASEDIR}/catkin_ws")
  CreateCatkinWorkspace("${CATKIN_WORKSPACE}")
endif()

if(NOT SYSTEM_HAS_SPDLOG)
  AddProject(spdlog
    GITHUB gabime/spdlog
    GIT_TAG v1.6.1
    CMAKE_ARGS -DSPDLOG_BUILD_EXAMPLE:BOOL=OFF -DSPDLOG_BUILD_SHARED:BOOL=ON
    SKIP_TEST
  )
endif()

AddProject(hpp-spline
  GITHUB gergondet/hpp-spline
  GIT_TAG master
  CMAKE_ARGS -DBUILD_TESTING:BOOL=OFF -DBUILD_PYTHON_INTERFACE:BOOL=OFF
  SKIP_TEST
)

AddProject(state-observation
  GITHUB jrl-umi3218/state-observation
  GIT_TAG master
  CMAKE_ARGS -DBUILD_STATE_OBSERVATION_TOOLS:BOOL=OFF
)

if(PYTHON_BINDING)
  AddProject(Eigen3ToPython
    GITHUB jrl-umi3218/Eigen3ToPython
    GIT_TAG master
  )
  set(SVA_DEPENDS DEPENDS Eigen3ToPython)
endif()

AddProject(SpaceVecAlg
  GITHUB jrl-umi3218/SpaceVecAlg
  GIT_TAG master
  ${SVA_DEPENDS}
)

AddProject(sch-core
  GITHUB jrl-umi3218/sch-core
  GIT_TAG master
  CMAKE_ARGS -DCMAKE_CXX_STANDARD=11
)

if(PYTHON_BINDING)
  AddProject(sch-core-python
    GITHUB jrl-umi3218/sch-core-python
    GIT_TAG master
    DEPENDS sch-core
  )
endif()

AddProject(RBDyn
  GITHUB jrl-umi3218/RBDyn
  GIT_TAG master
  DEPENDS SpaceVecAlg
)

AddProject(eigen-qld
  GITHUB jrl-umi3218/eigen-qld
  GIT_TAG master
  NO_NINJA
)

AddProject(eigen-quadprog
  GITHUB jrl-umi3218/eigen-quadprog
  GIT_TAG master
  NO_NINJA
)

if(WITH_LSSOL)
  AddProject(eigen-lssol
    GITE multi-contact/eigen-lssol
    GIT_TAG master
    GIT_USE_SSH
    NO_NINJA
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
  GIT_TAG master
  DEPENDS ${Tasks_DEPENDS}
)

AddProject(mc_rbdyn_urdf
  GITHUB jrl-umi3218/mc_rbdyn_urdf
  GIT_TAG master
  DEPENDS RBDyn
)

AddCatkinProject(mc_rtc_data
  GITHUB jrl-umi3218/mc_rtc_data
  GIT_TAG master
  WORKSPACE "${CATKIN_DATA_WORKSPACE}"
)
if(WITH_ROS_SUPPORT)
  AddCatkinProject(mc_rtc_msgs
    GITHUB jrl-umi3218/mc_rtc_msgs
    GIT_TAG master
    WORKSPACE "${CATKIN_DATA_WORKSPACE}"
  )
endif()

set(mc_rtc_DEPENDS Tasks mc_rbdyn_urdf mc_rtc_data hpp-spline state-observation)
if(NOT SYSTEM_HAS_SPDLOG)
  list(APPEND mc_rtc_DEPENDS spdlog)
endif()
if(WITH_ROS_SUPPORT)
  list(APPEND mc_rtc_DEPENDS mc_rtc_msgs)
endif()
AddProject(mc_rtc
  GITHUB jrl-umi3218/mc_rtc
  GIT_TAG master
  DEPENDS ${mc_rtc_DEPENDS}
)

if(WITH_ROS_SUPPORT)
  AddCatkinProject(mc_rtc_ros
    GITHUB jrl-umi3218/mc_rtc_ros
    GIT_TAG master
    WORKSPACE "${CATKIN_WORKSPACE}"
  )
endif()

install(CODE "message(\"Installation done\")")
