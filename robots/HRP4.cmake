option(WITH_HRP4 "Build HRP4 support, requires access to mc-hrp4 group on gite.lirmm.fr" OFF)

if(NOT WITH_HRP4)
  return()
endif()

AddCatkinProject(hrp4
  GITE mc-hrp4/hrp4
  GIT_TAG origin/master
  WORKSPACE data_ws
)

AddProject(mc-hrp4
  GITE mc-hrp4/mc-hrp4
  GIT_TAG origin/master
  DEPENDS hrp4 mc_rtc
)
