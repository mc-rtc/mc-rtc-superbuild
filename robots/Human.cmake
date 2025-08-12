option(WITH_HUMAN "Build human model for mc_rtc" OFF)

if(NOT WITH_HUMAN)
  return()
endif()

AddCatkinProject(
  human_description
  GITHUB jrl-umi3218/human_description
  GIT_TAG origin/master
  WORKSPACE data_ws
)

AddProject(
  mc_human
  GITHUB jrl-umi3218/mc_human
  GIT_TAG origin/master
  DEPENDS human_description mc_rtc
)
