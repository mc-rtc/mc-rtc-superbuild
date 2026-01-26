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

if(NOT WITH_Panda)
  return()
endif()

# See https://frankarobotics.github.io/docs/compatibility.html for compatibility between server on the robot/libfranka client
# For robots using FER 4.2.2, we are limited to <0.10.0, with 0.9.2 being the latest published tag
AddProject(
  libfranka
  GITHUB frankarobotics/libfranka
  GIT_TAG 0.9.2
  APT_DEPENDENCIES libtinyxml2-dev libpoco-dev
  CMAKE_ARGS -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DBUILD_EXAMPLES=ON
)
set(mc_panda_DEPENDS libfranka)

if(WITH_ROS_SUPPORT)
  AddCatkinProject(
    franka_description
    GITHUB frankarobotics/franka_description
    GIT_TAG origin/main
    WORKSPACE mc_rtc_ws
    DEPENDS libfranka
  )
  list(APPEND mc_panda_DEPENDS franka_description)

  # XXX: this is now incompatible with libfranka <0.10 which we require
  # to run on our older robots
  #
  # AddCatkinProject(
  #   franka_ros2
  #   GITHUB frankarobotics/franka_ros2
  #   GIT_TAG origin/humble
  #   WORKSPACE mc_rtc_ws
  #   DEPENDS libfranka
  # )
  # list(APPEND mc_panda_DEPENDS franka_ros2)
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

if(WITH_MC_FRANKA)
  AptInstall(libcap2-bin) # for setcap
  AddProject(
    mc_franka
    GITHUB jrl-umi3218/mc_franka
    GIT_TAG origin/master
    DEPENDS mc_rtc mc_panda
  )
endif()
