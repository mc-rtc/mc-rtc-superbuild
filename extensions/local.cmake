set(EXTENSIONS_DIR ${CMAKE_CURRENT_LIST_DIR}/superbuild-extensions)
include(${EXTENSIONS_DIR}/gui/mc_rtc-magnum.cmake)
#include(${EXTENSIONS_DIR}/interfaces/mc_mujoco.cmake)

# set(LOCAL_EXTENSIONS_DIR ${CMAKE_CURRENT_LIST_DIR}/local-extensions)
# include(${LOCAL_EXTENSIONS_DIR}/mc_mujoco.cmake)

AddProject(
  mc_tvm_sandbox
  GITHUB arntanguy/mc_tvm_sandbox
  GIT_TAG origin/main
  DEPENDS mc_rtc
)

include(${EXTENSIONS_DIR}/simulation/MuJoCo.cmake)

# Disable HRP4 from the default superbuild-extensions to install a custom one instead
# TODO: merge hrp4_mj_description
set(WITH_HRP4_BEFORE ${WITH_HRP4})
set(WITH_HRP4 OFF)
include(${EXTENSIONS_DIR}/interfaces/mc_mujoco.cmake)
set(WITH_HRP4 ${WITH_HRP4_BEFORE})

if(WITH_HRP4)
  AddProject(
    hrp4_mj_description
    # GITE mc-hrp4/hrp4_mj_description
    GITE hlefevre/hrp4_mj_description
    GIT_TAG origin/master
    DEPENDS mc_mujoco hrp4_description
  )
endif()
