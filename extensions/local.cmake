set(EXTENSIONS_DIR ${CMAKE_CURRENT_LIST_DIR}/superbuild-extensions)
include(${EXTENSIONS_DIR}/gui/mc_rtc-magnum.cmake)
include(${EXTENSIONS_DIR}/interfaces/mc_mujoco.cmake)
include(${EXTENSIONS_DIR}/controllers/lipm_walking_controller.cmake)
include(${EXTENSIONS_DIR}/plugins/mc_xsens_plugin.cmake)

AddProject(mc_udp
  GITHUB jrl-umi3218/mc_udp
  GIT_TAG origin/master
  DEPENDS mc_rtc
  APT_PACKAGES libmc-udp-dev python-mc-udp python3-mc-udp mc-udp-control
  CMAKE_ARGS -DBUILD_OPENRTM_SERVER=OFF -DBUILD_MC_RTC_CLIENT=ON
)

option(CDADANCE_AUTO_MODE "Automatic demo" OFF)
option(CDADANCE_REAL_ROBOT_MODE "Set to ON to run on the real robot" OFF)

set(ARGS "") 
list(APPEND ARGS "-DCDADANCE_AUTO_MODE=${CDADANCE_AUTO_MODE}")
list(APPEND ARGS "-DCDADANCE_REAL_ROBOT_MODE=${CDADANCE_REAL_ROBOT_MODE}")
message(STATUS "CDADance will build with CMAKE_ARGS=${ARGS}")
AddProject(CDADance
  GITHUB arntanguy/CDADance
  GIT_TAG origin/main
  CMAKE_ARGS ${ARGS}
  # optional
  # APT_DEPENDENCIES ros-humble-paho-mqtt-cpp
)
