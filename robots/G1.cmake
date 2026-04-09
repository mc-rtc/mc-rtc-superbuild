option(WITH_G1 "Build with Unitree's G1 robot support" OFF)

if(NOT WITH_G1)
  return()
endif()

AddCatkinProject(
  g1_description
  GITHUB Noceo200/g1_description
  GIT_TAG origin/main
  WORKSPACE data_ws
)

AddProject(
  mc_g1
  GITHUB Noceo200/mc_g1
  GIT_TAG origin/main
  DEPENDS g1_description mc_rtc
)
