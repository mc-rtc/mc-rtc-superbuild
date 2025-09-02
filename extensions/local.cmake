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

AptInstall(libxrandr-dev libxinerama-dev libxcursor-dev libxi-dev libglew-dev)

AddProject(
  mc_mujoco
  GITHUB rohanpsingh/mc_mujoco
  # GIT_TAG origin/main
  # GITHUB arntanguy/mc_mujoco
  GIT_TAG main
  CMAKE_ARGS -DMUJOCO_ROOT_DIR=${MUJOCO_ROOT_DIR}
  DEPENDS mc_rtc
)

if(WITH_HRP5)
  AddProject(
    hrp5p_mj_description
    GITHUB_PRIVATE isri-aist/hrp5p_mj_description
    GIT_TAG origin/main
    DEPENDS mc_mujoco
  )
endif()

if(WITH_HRP4CR)
  AddProject(
    hrp4cr_mj_description
    GITHUB_PRIVATE isri-aist/hrp4cr_mj_description
    GIT_TAG origin/main
    DEPENDS mc_mujoco
  )
endif()

if(WITH_HRP4)
  AddProject(
    hrp4_mj_description
    # GITE mc-hrp4/hrp4_mj_description
    GITE hlefevre/hrp4_mj_description
    GIT_TAG origin/master
    DEPENDS mc_mujoco hrp4_description
  )
endif()
