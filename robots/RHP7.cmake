option(WITH_RHP7 "Build RHP7 support" OFF)

if(NOT WITH_RHP7)
  return()
endif()

AddCatkinProject(
  rhp7_description
  GITHUB_PRIVATE isri-aist/rhp7_description
  GIT_TAG origin/main
  WORKSPACE data_ws
  CMAKE_ARGS ${MC_RTC_ROS_OPTION}
)

AddProject(
  mc_rhp7
  GITHUB_PRIVATE Yoshida-Lab-TUS/mc_rhp7
  GIT_TAG origin/main
  DEPENDS rhp7_description mc_rtc
)
