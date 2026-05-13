option(WITH_MIROKI "Build Miroki support" OFF)

if(NOT WITH_MIROKI)
  return()
endif()

if(NOT WITH_ROS_SUPPORT)
  message(FATAL_ERROR "ROS support is required to use the Miroki robot")
endif()

if(ROS_IS_ROS2)
  AddCatkinProject(
    miroki_description
    GITHUB isri-aist/miroki_description
    GIT_TAG origin/main
    WORKSPACE data_ws
  )
else() # ROS1
  message(ERROR "miroki_description is not supported on ROS1.")
endif()

AddProject(
  mc_miroki
  GITHUB isri-aist/mc_miroki
  GIT_TAG origin/main
  DEPENDS miroki_description mc_rtc
)

message(WARNING "[Miroki] Robot interface is not yet available...")
