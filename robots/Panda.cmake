option(WITH_Panda "Build Franka Emika Panda support" OFF)
option(WITH_PandaLIRMM "Build Panda support for LIRMM robots" OFF)
option(WITH_MC_FRANKA "Build mc_franka control interface" OFF)

if(WITH_PandaLIRMM AND NOT WITH_Panda)
  # PandaLIRMM module depends on Panda module If PandaLIRMM is explicitely selected,
  # install both.
  set(WITH_Panda
      ON
      CACHE BOOL "" FORCE
  )
endif()

set(Panda_DEPENDENCIES_FROM_SOURCE_DEFAULT ON)
if(DPKG AND WITH_ROS_SUPPORT)
  set(Panda_DEPENDENCIES_FROM_SOURCE_DEFAULT OFF)
endif()
cmake_dependent_option(
  Panda_DEPENDENCIES_FROM_SOURCE "Install Panda dependencies from source"
  ${Panda_DEPENDENCIES_FROM_SOURCE_DEFAULT} "WITH_Panda" OFF
)

if(NOT WITH_Panda)
  return()
endif()

if(Panda_DEPENDENCIES_FROM_SOURCE)
  AddProject(
    libfranka
    GITHUB frankaemika/libfranka
    GIT_TAG origin/0.8.0
  )
  set(mc_panda_DEPENDS libfranka)
  if(WITH_ROS_SUPPORT)
    AddCatkinProject(
      franka_ros
      GITHUB frankaemika/franka_ros
      GIT_TAG origin/0.8.1
      WORKSPACE mc_rtc_ws
      DEPENDS libfranka
    )
    list(APPEND mc_panda_DEPENDS franka_ros)
  endif()
else()
  if(NOT DPKG OR NOT WITH_ROS_SUPPORT)
    message(
      FATAL_ERROR
        "Panda dependencies binaries are only available from ROS APT mirrors, set Panda_DEPENDENCIES_FROM_SOURCE to OFF"
    )
  endif()
  AptInstall(ros-${ROS_DISTRO}-libfranka ros-${ROS_DISTRO}-franka-description)
endif()

if(WITH_MC_FRANKA)
  AptInstall(libcap2-bin) # for setcap
  AddProject(
    mc_franka
    GITHUB jrl-umi3218/mc_franka
    GIT_TAG origin/master
    DEPENDS mc_rtc mc_panda
  )
endif()

AddProject(
  mc_panda
  GITHUB jrl-umi3218/mc_panda
  GIT_TAG origin/master
  DEPENDS mc_rtc ${mc_panda_DEPENDS}
)

if(WITH_PandaLIRMM)
  AddProject(
    mc_panda_lirmm
    GITHUB jrl-umi3218/mc_panda_lirmm
    GIT_TAG origin/main
    DEPENDS mc_panda
  )
endif()
