option(WITH_HOAP3 "Build HOAP3 robot support" OFF)

if(NOT WITH_HOAP3)
  return()
endif()

AddCatkinProject(
  hoap3_description
  GITHUB_PRIVATE jrl-umi3218/hoap3_description
  GIT_TAG origin/master
  WORKSPACE data_ws
)

AddProject(
  mc-hoap3
  GITHUB_PRIVATE jrl-umi3218/mc-hoap3
  GIT_TAG origin/main
  DEPENDS hoap3_description mc_rtc
)
