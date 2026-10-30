option(WITH_XARM "Build xArm (xArm5, xArm6, xArm7) support" OFF)
option(WITH_XARM_DRIVER
       "Build xarm_driver control interface for UFactory xArm robots support" OFF
)

if(NOT WITH_XARM AND NOT WITH_XARM_DRIVER)
  return()
endif()

if(WITH_XARM)
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
endif()

if(WITH_XARM_DRIVER)
  AddProject(
    xArm-CPLUS-SDK
    GITHUB xArm-Developer/xArm-CPLUS-SDK
    GIT_TAG origin/master
  )

  AddProject(
    xarm_driver
    GITHUB isri-aist/xarm_driver
    GIT_TAG origin/main
    DEPENDS xArm-CPLUS-SDK uri
  )
endif()
