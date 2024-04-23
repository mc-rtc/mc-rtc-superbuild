option(WITH_RHPS1 "Build RHPS1 support" OFF)

if(NOT WITH_RHPS1)
  return()
endif()

AddCatkinProject(rhps1_description
  GITHUB_PRIVATE isri-aist/rhps1_description
  GIT_TAG origin/main
  WORKSPACE data_ws
)

AddProject(mc_rhps1
  GITHUB_PRIVATE isri-aist/mc_rhps1
  GIT_TAG origin/master
  DEPENDS rhps1_description mc_rtc
)
