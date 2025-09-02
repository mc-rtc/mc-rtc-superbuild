find_program(LSB_RELEASE lsb_release)

if(NOT LSB_RELEASE)
  message(FATAL_ERROR "lsb_release must be installed before running this script")
endif()

set(ROS_IS_ROS2 OFF)
set(APT_HAS_PYTHON2_PACKAGES ON)
execute_process(
  COMMAND lsb_release -sc
  OUTPUT_VARIABLE DISTRO
  OUTPUT_STRIP_TRAILING_WHITESPACE
)

if(EXISTS ${PROJECT_SOURCE_DIR}/cmake/linux/${DISTRO}.cmake)
  include(${PROJECT_SOURCE_DIR}/cmake/linux/${DISTRO}.cmake)
else()
  message(
    WARNING
      "Unknown distribution ${DISTRO}. This script will continue assuming you have all system dependencies available already"
  )
  message(
    AUTHOR_WARNING
      "You can add a file: ${PROJECT_SOURCE_DIR}/cmake/linux/${DISTRO}.cmake to inform this script about the distribution."
  )
endif()

if(NOT DEFINED USE_MC_RTC_APT_MIRROR)
  set(USE_MC_RTC_APT_MIRROR OFF)
endif()

if(WITH_ROS_SUPPORT
   AND NOT ROS_DISTRO
   AND NOT DEFINED ENV{ROS_DISTRO}
)
  message(
    FATAL_ERROR
      "Unknown ROS_DISTRO for ${DISTRO} and ROS environment has not been sourced."
  )
endif()

find_program(DPKG dpkg)
if(DPKG)
  if(APT_DEPENDENCIES)
    list(APPEND APT_DEPENDENCIES curl git)
    AptInstall(${APT_DEPENDENCIES})
  endif()
endif()

if(WITH_ROS_SUPPORT AND ROS_DISTRO)
  if(DPKG)
    if(${DISTRO} STREQUAL "buster")
      # XXX: Temporarely install catkin_tools with PIP instead of APT due to
      # https://robotics.stackexchange.com/questions/101172/cannot-install-catkin-tools-on-debian-buster-due-to-python-version-requirement
      # set(PYTHON_CAKTIN_TOOLS catkin_tools)
      execute_process(COMMAND pip install --user ${PIP_DEPENDENCIES})
    elseif("${ROS_DISTRO}" STREQUAL "kinetic" OR "${ROS_DISTRO}" STREQUAL "melodic")
      set(PYTHON_CAKTIN_TOOLS python-catkin-tools)
    elseif(NOT ROS_IS_ROS2)
      set(PYTHON_CAKTIN_TOOLS python3-catkin-tools)
    else()
      set(PYTHON_CAKTIN_TOOLS python3-colcon-common-extensions)
    endif()
    set(ROS_APT_DEPENDENCIES ros-${ROS_DISTRO}-ros-base ros-${ROS_DISTRO}-tf2-ros
                             ros-${ROS_DISTRO}-xacro ${PYTHON_CAKTIN_TOOLS}
    )
    if(ROS_IS_ROS2)
      list(APPEND ROS_APT_DEPENDENCIES ros-${ROS_DISTRO}-rviz2
           ros-${ROS_DISTRO}-geometry-msgs ros-${ROS_DISTRO}-rosidl-default-generators
           ros-${ROS_DISTRO}-rosidl-default-runtime
      )
    else()
      list(APPEND ROS_APT_DEPENDENCIES ros-${ROS_DISTRO}-common-msgs
           ros-${ROS_DISTRO}-rosdoc-lite ros-${ROS_DISTRO}-rviz
      )
    endif()
    if(NOT EXISTS /etc/apt/sources.list.d/ros-latest.list)
      message(STATUS "Adding ROS APT mirror for your system")
      execute_process(
        COMMAND sudo ${CMAKE_COMMAND} -E make_directory /etc/apt/sources.list.d
        RESULT_VARIABLE BASH_FAILED
      )
      if(BASH_FAILED)
        message(FATAL_ERROR "Failed to create /etc/apt/sources.list.d")
      endif()
      if(ROS_IS_ROS2)
        execute_process(
          COMMAND
            bash -c
            "sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg"
        )
      else()
        execute_process(
          COMMAND
            bash -c
            "curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -"
          RESULT_VARIABLE BASH_FAILED
          OUTPUT_QUIET ERROR_QUIET
        )
      endif()
      if(BASH_FAILED)
        message(FATAL_ERROR "Failed to add ROS signing key")
      endif()
      if(ROS_IS_ROS2)
        set(ROS_MIRROR
            "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu"
        )
      else()
        set(ROS_MIRROR "deb http://packages.ros.org/ros/ubuntu")
      endif()
      execute_process(
        COMMAND
          sudo bash -c
          "echo \"${ROS_MIRROR} ${DISTRO} main\" > /etc/apt/sources.list.d/ros-latest.list"
        RESULT_VARIABLE BASH_FAILED
      )
      if(BASH_FAILED)
        message(FATAL_ERROR "Failed to add ros-latest.list")
      endif()
    endif()
    AptInstall(${ROS_APT_DEPENDENCIES})
    if(NOT DEFINED ENV{ROS_DISTRO})
      set(ENV{PATH} "/opt/ros/${ROS_DISTRO}/bin:$ENV{PATH}")
      set(ENV{LD_LIBRARY_PATH}
          "/opt/ros/${ROS_DISTRO}/lib:/opt/ros/${ROS_DISTRO}/lib/x86_64-linux-gnu:$ENV{LD_LIBRARY_PATH}"
      )
      set(ENV{ROS_DISTRO} ${ROS_DISTRO})
      set(ENV{ROS_ETC_DIR} /opt/ros/${ROS_DISTRO}/etc/ros)
      set(ENV{ROS_ROOT} /opt/ros/${ROS_DISTRO}/share/ros)
      if("${ROS_DISTRO}" STREQUAL "melodic" OR "${ROS_DISTRO}" STREQUAL "kinetic")
        set(ENV{ROS_PYTHON_VERSION} 2)
      else()
        set(ENV{ROS_PYTHON_VERSION} 3)
      endif()
      AppendROSWorkspace(/opt/ros/${ROS_DISTRO} /opt/ros/${ROS_DISTRO}/share/)
    endif()
  else()
    if(NOT DEFINED ENV{ROS_DISTRO})
      message(
        FATAL_ERROR
          "This script only knows how to install ROS on Debian derivatives, source your ROS setup before running CMake again."
      )
    endif()
  endif()
endif()

if(COMMAND mc_rtc_extra_steps)
  mc_rtc_extra_steps()
endif()
