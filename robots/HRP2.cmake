option(WITH_HRP2 "Build HRP2-Kai support, requires access to mc-hrp2 group on gite.lirmm.fr" OFF)

if(NOT WITH_HRP2)
  return()
endif()

AddCatkinProject(hrp2_drc_description
  GITHUB isri-aist/hrp2_drc_description
  WORKSPACE data_ws
)

AddProject(mc-hrp2
  GITHUB isri-aist/mc-hrp2
  GIT_TAG origin/master
  DEPENDS hrp2_drc_description mc_rtc
)
