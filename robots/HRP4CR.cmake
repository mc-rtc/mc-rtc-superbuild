option(WITH_HRP4CR "Build HRP4CR support, requires access to isri-aist projects on github" OFF)

if(NOT WITH_HRP4CR)
  return()
endif()

AddCatkinProject(hrp4cr_description
  GITHUB isri-aist/hrp4cr_description
  WORKSPACE data_ws
  GIT_USE_SSH
)

AddProject(mc-hrp4cr
  GITHUB isri-aist/mc_hrp4cr
  GIT_USE_SSH
  DEPENDS hrp4cr_description mc_rtc
)
