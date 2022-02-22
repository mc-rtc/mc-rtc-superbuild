option(WITH_HRP5 "Build HRP5 support, requires access to mc-hrp5 group on gite.lirmm.fr" OFF)

if(NOT WITH_HRP5)
  return()
endif()

AddCatkinProject(hrp5_p_description
  GITE mc-hrp5/hrp5_p_description
  GIT_TAG origin/master
  WORKSPACE data_ws
)

AddProject(mc_hrp5_p
  GITE mc-hrp5/mc_hrp5_p
  GIT_TAG origin/master
  DEPENDS hrp5_p_description mc_rtc
)
