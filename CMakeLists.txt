cmake_minimum_required(VERSION 3.20)

project(mc_rtc_superbuild)
enable_testing()

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  message(STATUS "Setting default build type to RelWithDebInfo as none was provided")
  set(CMAKE_BUILD_TYPE "RelWithDebInfo" CACHE STRING "Choose the type of a build" FORCE)
endif()

include(cmake/project.cmake)
include(cmake/ros.cmake)

if(APPLE)
  include(cmake/macos-dependencies.cmake)
endif()

if(WIN32)
  include(cmake/win32-dependencies.cmake)
endif()

if(UNIX AND NOT APPLE)
  include(cmake/linux-dependencies.cmake)
endif()

if(WITH_ROS_SUPPORT)
  set(CATKIN_DATA_WORKSPACE "${SOURCE_DESTINATION}/catkin_data_ws")
  CreateCatkinWorkspace("${CATKIN_DATA_WORKSPACE}")
  set(CATKIN_WORKSPACE "${SOURCE_DESTINATION}/catkin_ws")
  CreateCatkinWorkspace("${CATKIN_WORKSPACE}")
else()
  set(CATKIN_DATA_WORKSPACE "${SOURCE_DESTINATION}")
  set(CATKIN_WORKSPACE "${SOURCE_DESTINATION}")
endif()

AddProject(ndcurves
  GITHUB loco-3d/ndcurves
  GIT_TAG v1.1.1
  CMAKE_ARGS -DBUILD_PYTHON_INTERFACE:BOOL=OFF
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
  list(APPEND SpaceVecAlg_DEPENDS Eigen3ToPython)
endif()

AddProject(SpaceVecAlg
  GITHUB jrl-umi3218/SpaceVecAlg
  GIT_TAG master
  DEPENDS ${SpaceVecAlg_DEPENDS}
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
    DEPENDS sch-core SpaceVecAlg
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
  list(APPEND mc_rtc_DEPENDS mc_rtc_msgs)
endif()

list(APPEND mc_rtc_DEPENDS Tasks mc_rbdyn_urdf mc_rtc_data ndcurves state-observation)
if(TARGET spdlog)
  list(APPEND mc_rtc_DEPENDS spdlog)
endif()
if(NOT DEFINED MC_LOG_UI_PYTHON_EXECUTABLE)
  set(MC_LOG_UI_PYTHON_EXECUTABLE python)
endif()
if(WITH_ROS_SUPPORT)
  set(MC_RTC_ROS_OPTION "-DDISABLE_ROS=OFF")
else()
  set(MC_RTC_ROS_OPTION "-DDISABLE_ROS=ON")
endif()
AddProject(mc_rtc
  GITHUB jrl-umi3218/mc_rtc
  GIT_TAG master
  CMAKE_ARGS -DMC_LOG_UI_PYTHON_EXECUTABLE=${MC_LOG_UI_PYTHON_EXECUTABLE} ${MC_RTC_ROS_OPTION}
  DEPENDS ${mc_rtc_DEPENDS}
)

if(WITH_ROS_SUPPORT)
  AddCatkinProject(mc_rtc_ros
    GITHUB jrl-umi3218/mc_rtc_ros
    GIT_TAG master
    WORKSPACE "${CATKIN_WORKSPACE}"
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

install(CODE "message(\"Installation done\")")
