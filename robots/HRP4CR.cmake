option(WITH_HRP4CR
       "Build HRP4CR support, requires access to isri-aist projects on github" OFF
)

if(NOT WITH_HRP4CR)
  return()
endif()

AddCatkinProject(
  hrp4cr_description
  GITHUB_PRIVATE isri-aist/hrp4cr_description
  WORKSPACE data_ws
)

AddProject(
  mc-hrp4cr
  GITHUB_PRIVATE isri-aist/mc_hrp4cr
  DEPENDS hrp4cr_description mc_rtc
)
