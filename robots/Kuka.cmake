option(WITH_KUKA "Build KUKA support" OFF)

if(NOT WITH_ROS_SUPPORT)
  message(FATAL_ERROR "ROS support is required to use the KUKA robot")
endif()

if(WITH_KUKA)
  AddProject(
    fri
    GITHUB lbr-stack/fri
    GIT_TAG origin/fri-1.15
  )

  AddProject(
    lbr_fri_idl
    GITHUB lbr-stack/lbr_fri_idl
    GIT_TAG origin/fri-1
    CMAKE_ARGS -DBUILD_TESTING=OFF
    DEPENDS fri
  )

  if(ROS_IS_ROS2)
    AddCatkinProject(
      lbr_fri_ros2_stack
      GITHUB lbr-stack/lbr_fri_ros2_stack
      GIT_TAG origin/${ROS_DISTRO}
      WORKSPACE data_ws
      DEPENDS lbr_fri_idl INSTALL_DEPENDENCIES
    )
  else() # ROS1
    message(ERROR "KUKA description is not supported on ROS1.")
  endif()

  AddProject(
    mc_kuka_fri
    GITHUB isri-aist/mc_kuka_fri
    GIT_TAG origin/main
    DEPENDS lbr_fri_ros2_stack mc_rtc
  )
endif()
