option(WITH_ROS2_CONTROL_DRIVER "Build the ros2_control_driver plugin" OFF)

if(NOT WITH_ROS2_CONTROL_DRIVER)
  return()
endif()

if(NOT WITH_ROS_SUPPORT OR NOT ROS_IS_ROS2)
  message(FATAL_ERROR "ROS 2 support is required to build ros2_control_driver")
endif()

if(NOT WITH_URI)
  message(FATAL_ERROR "WITH_ROS2_CONTROL_DRIVER requires WITH_URI=ON")
endif()

AptInstall(ros-${ROS_DISTRO}-controller-manager-msgs)

AddProject(
  ros2_control_driver
  GITHUB isri-aist/ros2_control_driver
  GIT_TAG origin/main
  DEPENDS uri
)
