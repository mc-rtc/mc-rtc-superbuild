option(WITH_Sawyer "Build Sawyer support" OFF)

if(NOT WITH_Sawyer)
  return()
endif()

AddCatkinProject(sawyer_description
  GITHUB jrl-umi3218/sawyer_description
  GIT_TAG master
  WORKSPACE "${CATKIN_DATA_WORKSPACE}"
)

AddProject(mc-sawyer
  GITHUB jrl-umi3218/mc-sawyer
  GIT_TAG master
  DEPENDS sawyer_description mc_rtc
)
