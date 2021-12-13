option(WITH_Pepper "Build Pepper support" OFF)

if(NOT WITH_Pepper)
  return()
endif()

AddCatkinProject(pepper_description
  GITHUB jrl-umi3218/pepper_description
  GIT_TAG master
  WORKSPACE "${CATKIN_DATA_WORKSPACE}"
)

AddProject(mc_pepper
  GITHUB jrl-umi3218/mc_pepper
  GIT_TAG master
  DEPENDS pepper_description mc_rtc
)

