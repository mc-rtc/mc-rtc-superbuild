option(WITH_OPENARM "Build OpenArm support" OFF)

if(NOT WITH_OPENARM)
  return()
endif()

if(NOT WITH_ROS_SUPPORT)
  message(FATAL_ERROR "ROS support is required to use the OpenArm robot")
endif()

if(ROS_IS_ROS2)
  AddCatkinProject(
    openarm_description
    GITHUB enactic/openarm_description
    GIT_TAG origin/main
    WORKSPACE data_ws
  )
else()
  message(FATAL_ERROR "Description for OpenArm is not support for ROS1")
endif()

AddProject(
  mc_openarm
  GITHUB isri-aist/mc_openarm
  GIT_TAG origin/master
  DEPENDS openarm_description mc_rtc
)
