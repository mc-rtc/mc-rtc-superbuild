# set(EXTENSIONS_DIR ${CMAKE_CURRENT_LIST_DIR}/superbuild-extensions)
# include(${EXTENSIONS_DIR}/gui/mc_rtc-magnum.cmake)

AddProject(mc-rtc-superbuild-private-ci
  GITHUB_PRIVATE isri-aist/mc-rtc-superbuild-private-ci 
  CLONE_ONLY
)
