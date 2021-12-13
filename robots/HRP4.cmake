option(WITH_HRP4 "Build HRP4 support, requires access to mc-hrp4 group on gite.lirmm.fr" OFF)

if(NOT WITH_HRP4)
  return()
endif()

AddCatkinProject(hrp4
  GITE mc-hrp4/hrp4
  GIT_TAG master
  WORKSPACE "${CATKIN_DATA_WORKSPACE}"
  GIT_USE_SSH
)

AddProject(mc-hrp4
  GITE mc-hrp4/mc-hrp4
  GIT_TAG master
  GIT_USE_SSH
  DEPENDS hrp4 mc_rtc
)
