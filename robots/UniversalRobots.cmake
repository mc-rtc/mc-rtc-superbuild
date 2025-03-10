option(WITH_MC_RTDE "Build mc_rtde control interface for UR5E and UR10 support (>=CB3)" OFF)
option(WITH_UR3E "Build UR5E support" OFF)
option(WITH_UR5E "Build UR5E support" OFF)
option(WITH_UR10 "Build UR10 support" OFF)

function(AddAptRepository PPA)
  execute_process(COMMAND bash -c "${SUDO_CMD} add-apt-repository ${PPA} -y && ${SUDO_CMD} apt-get update" RESULT_VARIABLE BASH_FAILED)
  if(BASH_FAILED)
    message(FATAL_ERROR "Failed to add ${PPA} mirror")
  endif()
endfunction()

if(WITH_MC_RTDE)
  AptInstall(libcap2-bin) # For setcap

  # For CB>=3 support
  AddAptRepository("ppa:sdurobotics/ur-rtde")
  AptInstall(librtde librtde-dev)

  # For CB<=2 support
  AddProject(ur_modern_driver
    GITHUB jrl-umi3218/ur_modern_driver
    GIT_TAG origin/main
  )

  AddProject(mc_rtde
    GITHUB isri-aist/mc_rtde 
    GIT_TAG origin/topic/RealTimeControl
    DEPENDS mc_rtc ur_modern_driver 
  )
endif()


if(WITH_UR10 OR WITH_UR5E OR WITH_UR3E)
  if(ROS_IS_ROS2)
    AddCatkinProject(ur_description
      GITHUB UniversalRobots/Universal_Robots_ROS2_Description
      GIT_TAG origin/humble
      WORKSPACE data_ws
    )
  else() # ROS1
    AddCatkinProject(ur_description
      GITHUB ros-industrial/universal_robot
      GIT_TAG noetic-devel/ur_description
      WORKSPACE data_ws
    )
  endif()
endif()

if(WITH_UR10)
  AddCatkinProject(mc_ur10_description
    GITHUB isri-aist/mc_ur10_description
    GIT_TAG origin/main
    DEPENDS ur_description
    WORKSPACE data_ws
  )
  AddProject(mc_ur10
    GITHUB isri-aist/mc_ur10
    GIT_TAG origin/main
    DEPENDS mc_ur10_description mc_rtc
  )
endif()

if(WITH_UR5E)
  AddCatkinProject(mc_ur5e_description
    GITHUB isri-aist/mc_ur5e_description
    GIT_TAG origin/main
    DEPENDS ur_description
    WORKSPACE data_ws
  )
  AddProject(mc_ur5e
    GITHUB isri-aist/mc_ur5e
    GIT_TAG origin/main
    DEPENDS mc_ur5e_description mc_rtc
  )
endif()

if(WITH_UR3E)
  AddCatkinProject(mc_ur3e_description
    GITHUB isri-aist/mc_ur3e_description
    GIT_TAG origin/main
    DEPENDS ur_description
    WORKSPACE data_ws
  )
  AddProject(mc_ur3e
    GITHUB isri-aist/mc_ur3e
    GIT_TAG origin/master
    DEPENDS mc_ur3e_description mc_rtc
  )
endif()
