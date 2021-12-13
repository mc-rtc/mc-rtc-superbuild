option(WITH_HRP5 "Build HRP5 support, requires access to mc-hrp5 group on gite.lirmm.fr" OFF)

if(NOT WITH_HRP4)
  return()
endif()

AddCatkinProject(hrp5_p_description
  GITE mc-hrp5/hrp5_p_description
  GIT_TAG master
  WORKSPACE "${CATKIN_DATA_WORKSPACE}"
  GIT_USE_SSH
)

AddProject(mc_hrp5_p
  GITE mc-hrp5/mc_hrp5_p
  GIT_TAG master
  GIT_USE_SSH
  DEPENDS hrp5_p_description mc_rtc
)
