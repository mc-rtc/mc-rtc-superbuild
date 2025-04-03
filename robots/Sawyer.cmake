option(WITH_Sawyer "Build Sawyer support" OFF)

if(NOT WITH_Sawyer)
  return()
endif()

AddCatkinProject(
  sawyer_description
  GITHUB
  jrl-umi3218/sawyer_robot
  GIT_TAG
  origin/master
  WORKSPACE
  data_ws
)

AddProject(
  mc-sawyer
  GITHUB
  jrl-umi3218/mc-sawyer
  GIT_TAG
  origin/master
  DEPENDS
  sawyer_description
  mc_rtc
)
