option(WITH_GO1 "Build with Unitree's GO1 robot support" OFF)

if(NOT WITH_GO1)
  return()
endif()

AddCatkinProject(
  mc_go1_description
  GITHUB jrl-umi3218/mc_go1_description
  GIT_TAG origin/main
  WORKSPACE data_ws
)

AddProject(
  mc_go1
  GITHUB jrl-umi3218/mc_go1
  GIT_TAG origin/main
  DEPENDS mc_go1_description mc_rtc
)
