option(WITH_Kinova "Build Kinova support" OFF)

if(NOT WITH_Kinova)
  return()
endif()

if(NOT WITH_ROS_SUPPORT)
  message(FATAL_ERROR "ROS support is required to use the Kinova robot")
endif()

if(ROS_IS_ROS2)
  AptInstall(
    ros-${ROS_DISTRO}-kortex-api ros-${ROS_DISTRO}-kortex-bringup
    ros-${ROS_DISTRO}-kortex-description ros-${ROS_DISTRO}-kortex-driver
  )

  AddProject(
    mc_kinova
    GITHUB mathieu-celerier/mc_kinova
    GIT_TAG origin/main
    APT_PACKAGES mc_rtc ros-${ROS_DISTRO}-kortex-api ros-${ROS_DISTRO}-kortex-bringup
                 ros-${ROS_DISTRO}-kortex-description ros-${ROS_DISTRO}-kortex-driver
  )
else()
  AddCatkinProject(
    ros_kortex
    GITHUB Kinovarobotics/ros_kortex
    GIT_TAG origin/${ROS_DISTRO}-devel
    WORKSPACE data_ws
  )

  AddProject(
    mc_kinova
    GITHUB isri-aist/mc_kinova
    GIT_TAG origin/main
    DEPENDS mc_rtc ros_kortex
  )
endif()
