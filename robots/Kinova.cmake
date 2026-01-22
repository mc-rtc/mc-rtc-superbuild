option(WITH_Kinova "Build Kinova support" OFF)

if(NOT WITH_Kinova)
  return()
endif()

if(NOT WITH_ROS_SUPPORT OR NOT ROS_IS_ROS2)
  message(FATAL_ERROR "ROS2 support is required to use the Kinova robot")
endif()

AddCatkinProject(
  ros_kortex
  GITHUB Kinovarobotics/ros2_kortex
  GIT_TAG origin/${ROS_DISTRO}
  WORKSPACE data_ws INSTALL_DEPENDENCIES
)

AddProject(
  mc_kinova
  GITHUB isri-aist/mc_kinova
  GIT_TAG origin/main
  DEPENDS mc_rtc ros_kortex
)
