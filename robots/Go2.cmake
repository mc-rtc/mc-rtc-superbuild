option(WITH_GO2 "Build with Unitree's GO2 robot support" OFF)

if(NOT WITH_GO2)
  return()
endif()

AddCatkinProject(
  go2_description
  GITHUB isri-aist/go2_description
  GIT_TAG origin/master
  WORKSPACE data_ws
)

AddProject(
  mc_go2
  GITHUB isri-aist/mc_go2
  GIT_TAG origin/main
  DEPENDS go2_description mc_rtc
)
