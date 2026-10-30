option(WITH_Kinova "Build Kinova support" OFF)
option(WITH_KORTEX_DRIVER
       "Build kortex_driver control interface for Kinova Gen3, Gen3 Lite support" OFF
)

if(NOT WITH_Kinova AND NOT WITH_KORTEX_DRIVER)
  return()
endif()

if(WITH_Kinova)
  if(NOT WITH_ROS_SUPPORT OR NOT ROS_IS_ROS2)
    message(FATAL_ERROR "ROS2 support is required to use the Kinova robot")
  endif()

  AddCatkinProject(
    ros_kortex
    GITHUB Kinovarobotics/ros2_kortex
    GIT_TAG origin/${ROS_DISTRO}
    WORKSPACE data_ws INSTALL_DEPENDENCIES PACKAGES_SELECT kortex_description
  )

  AddProject(
    mc_kinova
    GITHUB isri-aist/mc_kinova
    GIT_TAG origin/main
    DEPENDS mc_rtc ros_kortex
  )

  AddProject(
    mc_kortex
    GITHUB mathieu-celerier/mc_kortex
    GIT_TAG origin/main
    DEPENDS mc_rtc ros_kortex
  )
endif()

if(WITH_KORTEX_DRIVER)

  AddProject(
    kortex_driver
    GITHUB isri-aist/kortex_driver
    GIT_TAG origin/main
    DEPENDS uri
  )
endif()
