option(WITH_XARM "Build xArm (xArm5, xArm6, xArm7) support" OFF)

if(NOT WITH_XARM)
  return()
endif()

set(XARM_ROS2_BRANCH "${ROS_DISTRO}")

if("${ROS_DISTRO}" STREQUAL "lyrical")
  set(XARM_ROS2_BRANCH "rolling")
endif()

AddCatkinProject(
  xarm_ros2
  GITHUB xArm-Developer/xarm_ros2
  GIT_TAG origin/${XARM_ROS2_BRANCH}
  WORKSPACE data_ws INSTALL_DEPENDENCIES PACKAGES_SELECT xarm_description
)

AddProject(
  mc_xarm
  GITHUB isri-aist/mc_xarm
  GIT_TAG origin/main
  DEPENDS xarm_ros2 mc_rtc
)
