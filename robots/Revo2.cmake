option(WITH_Revo2 "Build with BrainCo's Revo2 dexterous hand support" OFF)

if(NOT WITH_Revo2)
  return()
endif()

AddCatkinProject(
  revo2_description
  GITHUB isri-aist/revo2_description
  GIT_TAG origin/main
  WORKSPACE data_ws
)

AddProject(
  mc_revo2
  GITHUB isri-aist/mc_revo2
  GIT_TAG origin/main
  DEPENDS revo2_description mc_rtc
)
