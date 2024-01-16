option(WITH_HRP4 "Build HRP4 support, requires access to mc-hrp4 group on gite.lirmm.fr" OFF)

if(NOT WITH_HRP4)
  return()
endif()

AddCatkinProject(hrp4_description
  GITHUB_PRIVATE isri-aist/hrp4_description
  GIT_TAG origin/main
  WORKSPACE data_ws
)

AddProject(mc-hrp4
  GITHUB_PRIVATE isri-aist/mc-hrp4
  GIT_TAG origin/main
  DEPENDS hrp4_description mc_rtc
)
