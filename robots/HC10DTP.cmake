option(WITH_HC10DTP "Build Yaskawa HC10DTP support for mc_rtc" OFF)

if(NOT WITH_HC10DTP)
  return()
endif()

AddCatkinProject(
  hc10dtp_description
  GITE adennaoui/hc10dtp_description
  GIT_TAG origin/main
  WORKSPACE data_ws
)

AddProject(
  mc_hc10dtp
  GITE adennaoui/mc_hc10dtp
  GIT_TAG origin/master
  DEPENDS hc10dtp_description mc_rtc
)
