option(WITH_Kinova "Build Kinova support" OFF)

if(NOT WITH_Kinova)
	return()
endif()

if(NOT WITH_ROS_SUPPORT)
  message(FATAL_ERROR "ROS support is required to use the Kinova robot")
endif()

if(ROS_IS_ROS2)
  execute_process(COMMAND bash -c "sudo curl https://packages.osrfoundation.org/gazebo.gpg --output /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg")
  set(GAZEBO_MIRROR "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs)")
  execute_process(COMMAND sudo bash -c "echo \"${GAZEBO_MIRROR} main\" | sudo tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null")
  AptInstall(gz-harmonic)
else()
  AptInstall(ros-${ROS_DISTRO}-gazebo-ros)
endif()

AptInstall(
  ros-${ROS_DISTRO}-controller-manager
  ros-${ROS_DISTRO}-control-msgs
  ros-${ROS_DISTRO}-control-toolbox
  ros-${ROS_DISTRO}-moveit-ros-planning-interface
)

# Install conan if needed
find_program(CONAN conan)
if(NOT CONAN)
  find_program(PYTHON3 python3)
  if(NOT PYTHON3)
    message(FATAL_ERROR "Must have python3 to install conan to use the Kinova robot")
  endif()
  execute_process(COMMAND /usr/bin/python3 -m pip install --break-system-packages conan>=1.60.1 COMMAND_ERROR_IS_FATAL ANY)
  find_program(CONAN conan)
  if(NOT CONAN)
    message(FATAL_ERROR "Conan installation went wrong")
  endif()
  file(REAL_PATH ${CMAKE_C_COMPILER} CONAN_C_COMPILER)
  file(REAL_PATH ${CMAKE_CXX_COMPILER} CONAN_CXX_COMPILER)
  execute_process(COMMAND ${CMAKE_COMMAND} -E env CC=${CONAN_C_COMPILER} CXX=${CONAN_CXX_COMPILER} ${CONAN} profile new default --detect COMMAND_ERROR_IS_FATAL ANY)
  execute_process(COMMAND ${CONAN} profile update settings.compiler.libcxx=libstdc++11 default COMMAND_ERROR_IS_FATAL ANY)
endif()
if(CONAN_VERSION_OUTPUT MATCHES "Conan version (1\\.[0-9]+\\.[0-9]+)")
  # Conan 1.x
  execute_process(
    COMMAND ${CONAN} config set general.revisions_enabled=1
    RESULT_VARIABLE CONAN_RESULT
  )
else()
  # Conan 2.x
  file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/conan_global.conf" "core.revisions_enabled=1\n")
  execute_process(
    COMMAND ${CONAN} config install "${CMAKE_CURRENT_BINARY_DIR}/conan_global.conf"
    RESULT_VARIABLE CONAN_RESULT
  )
endif()

if(NOT CONAN_RESULT EQUAL 0)
  message(FATAL_ERROR "Failed to set Conan revisions_enabled option")
endif()

if(ROS_IS_ROS2)
  # Dependencies for bota
  AptInstall(
    ros-${ROS_DISTRO}-diagnostic-updater
    ros-${ROS_DISTRO}-xacro
    ros-${ROS_DISTRO}-joint-state-publisher
    ros-${ROS_DISTRO}-gripper-controllers
    ros-${ROS_DISTRO}-joint-trajectory-controller
    ros-${ROS_DISTRO}-joint-state-broadcaster
    ros-${ROS_DISTRO}-robotiq-description
    ros-${ROS_DISTRO}-ros-gz-bridge
    ros-${ROS_DISTRO}-ros-gz-sim
    ros-${ROS_DISTRO}-moveit-planners
    ros-${ROS_DISTRO}-moveit-simple-controller-manager
    ros-${ROS_DISTRO}-joint-state-publisher-gui
    ros-${ROS_DISTRO}-moveit-configs-utils
    ros-${ROS_DISTRO}-moveit-ros-visualization
    ros-${ROS_DISTRO}-moveit-setup-assistant
    ros-${ROS_DISTRO}-picknik-reset-fault-controller
    ros-${ROS_DISTRO}-picknik-twist-controller
    ros-${ROS_DISTRO}-ros-testing
    ros-${ROS_DISTRO}-gz-ros2-control
  )

  AddCatkinProject(soem
    GITHUB botasys/soem
    GIT_TAG origin/foxy-devel
    WORKSPACE data_ws
  )

  set(ROS_KORTEX_NAME ros2_kortex)
  AddCatkinProject(ros2_kortex
    GITHUB Kinovarobotics/ros2_kortex
    GIT_TAG origin/main
    WORKSPACE data_ws
  )

  AddCatkinProject(bota_driver
    GIT_REPOSITORY https://gitlab.com/botasys/bota_driver
    GIT_TAG origin/iron-devel
    WORKSPACE data_ws
    DEPENDS soem
  )
else()
  # Dependencies for bota
  AptInstall(
    libxmlrpcpp-dev
    librosconsole-dev
    ros-${ROS_DISTRO}-diagnostic-updater
    ros-${ROS_DISTRO}-soem
    ros-${ROS_DISTRO}-ethercat-grant
  )

  set(ROS_KORTEX_NAME ros_kortex)
  AddCatkinProject(ros_kortex
    GITHUB Kinovarobotics/ros_kortex
    GIT_TAG origin/${ROS_DISTRO}-devel
    WORKSPACE data_ws
  )

  AddCatkinProject(bota_driver
    GIT_REPOSITORY https://gitlab.com/botasys/bota_driver
    GIT_TAG origin/master
    WORKSPACE data_ws)
endif()

AddProject(mc_kinova
  GITHUB mathieu-celerier/mc_kinova
	GIT_TAG origin/topic/bota_ft_sensor_w_DS4
  DEPENDS mc_rtc ${ROS_KORTEX_NAME} bota_driver
)
