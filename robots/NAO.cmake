option(WITH_NAO "Build NAO support" OFF)

if(NOT WITH_NAO)
  return()
endif()

AddCatkinProject(nao_description
  GITHUB jrl-umi3218/nao_description
  GIT_TAG origin/master
  WORKSPACE data_ws
)

AddProject(mc_nao
  GITHUB jrl-umi3218/mc_nao
  GIT_TAG origin/master
  DEPENDS nao_description mc_rtc
)
