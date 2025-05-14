set(EXTENSIONS_DIR ${CMAKE_CURRENT_LIST_DIR}/superbuild-extensions)
include(${EXTENSIONS_DIR}/gui/mc_rtc-magnum.cmake)
#include(${EXTENSIONS_DIR}/interfaces/mc_mujoco.cmake)

set(LOCAL_EXTENSIONS_DIR ${CMAKE_CURRENT_LIST_DIR}/local-extensions)
include(${LOCAL_EXTENSIONS_DIR}/mc_mujoco.cmake)

AddProject(mc_tvm_sandbox
  GITHUB arntanguy/mc_tvm_sandbox
  GIT_TAG origin/main
  DEPENDS mc_rtc
)
