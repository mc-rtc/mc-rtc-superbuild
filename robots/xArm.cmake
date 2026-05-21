option(WITH_XARM "Build xArm (xArm5, xArm6, xArm7) support" OFF)

if(NOT WITH_XARM)
  return()
endif()

AddCatkinProject(
  xarm_ros2
  GITHUB xArm-Developer/xarm_ros2
  GIT_TAG origin/${ROS_DISTRO}
  WORKSPACE data_ws INSTALL_DEPENDENCIES
)

AddProject(
  mc_xarm
  GITHUB isri-aist/mc_xarm
  GIT_TAG origin/main
  DEPENDS xarm_ros2 mc_rtc
)
