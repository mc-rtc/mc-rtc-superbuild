option(WITH_STAUBLI "Build Staubli support" OFF)

if(NOT WITH_ROS_SUPPORT)
  message(FATAL_ERROR "ROS support is required to use the Staubli robot")
endif()

if(WITH_STAUBLI)
  if(ROS_IS_ROS2)
    AddCatkinProject(
      staubli_description
      GITHUB isri-aist/staubli_description
      GIT_TAG origin/main
      WORKSPACE data_ws
    )
  else() # ROS1
    message(ERROR "staubli description is not supported on ROS1.")
  endif()

  AddProject(
    mc_staubli
    GITHUB isri-aist/mc_staubli
    GIT_TAG origin/main
    DEPENDS staubli_description mc_rtc
  )

  AddProject(
    mc_staubli_val3
    GITHUB isri-aist/mc_staubli_val3
    GIT_TAG origin/main
    DEPENDS mc_staubli
  )
endif()
