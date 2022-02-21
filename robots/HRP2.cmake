option(WITH_HRP2 "Build HRP2-Kai support, requires access to mc-hrp2 group on gite.lirmm.fr" OFF)

if(NOT WITH_HRP2)
  return()
endif()

AddCatkinProject(hrp2_drc_description
  GITE mc-hrp2/hrp2_drc_description
  WORKSPACE data_ws
  GIT_USE_SSH
)

AddProject(mc-hrp2
  GITE mc-hrp2/mc-hrp2
  GIT_TAG origin/master
  GIT_USE_SSH
  DEPENDS hrp2_drc_description mc_rtc
)
