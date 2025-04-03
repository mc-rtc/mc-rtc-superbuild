option(WITH_Talos "Build Talos support" OFF)

if(NOT WITH_Talos)
  return()
endif()

AddCatkinProject(
  talos_robot
  GITHUB pal-robotics/talos_robot
  GIT_TAG origin/kinetic-devel
  WORKSPACE data_ws
)

AddProject(
  mc-talos
  GITHUB jrl-umi3218/mc-talos
  GIT_TAG origin/main
  DEPENDS talos_robot mc_rtc
)
