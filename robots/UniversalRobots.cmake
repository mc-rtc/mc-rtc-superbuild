option(WITH_MC_RTDE "Build mc_rtde control interface for UR5E and UR10 support" OFF)
option(WITH_UR5E "Build UR5E support" OFF)
option(WITH_UR10 "Build UR10 support" OFF)

if(WITH_MC_RTDE)
  AddGitSource(GITLAB_SDUROBOTICS git@gitlab.com:sdurobotics:)
  AddProject(ur_rtde
    GITLAB_SDUROBOTICS ur_rtde
    GIT_TAG origin/v1.6.0
  )

  AddProject(mc_rtde
    GITHUB isri-aist/mc_rtde 
    GIT_TAG origin/main
    DEPENDS mc_rtc ur_rtde 
  )
endif()

if(WITH_UR10 OR WITH_UR5E)
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

