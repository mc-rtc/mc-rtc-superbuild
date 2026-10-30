option(WITH_TRIORB "Build TriOrb support" OFF)
option(
  WITH_TRIORB_DRIVER
  "Build triorb_driver control interface for TriOrb omnidirectional mobile base support"
  OFF
)

if(NOT WITH_TRIORB AND NOT WITH_TRIORB_DRIVER)
  return()
endif()

if(WITH_TRIORB)
  AddCatkinProject(
    triorb_description
    GITHUB isri-aist/mc_triorb_description
    GIT_TAG origin/main
    WORKSPACE data_ws INSTALL_DEPENDENCIES
  )

  AddProject(
    mc_trirob
    GITHUB isri-aist/mc_triorb
    GIT_TAG origin/main
    DEPENDS triorb_description mc_rtc
  )
endif()

if(WITH_TRIORB_DRIVER)
  AddProject(
    triorb_driver
    GITHUB isri-aist/triorb_driver
    GIT_TAG origin/main
    DEPENDS uri
  )
endif()
