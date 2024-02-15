if(WITH_ROS_SUPPORT)
  CreateCatkinWorkspace(ID data_ws DIR "catkin_data_ws" CATKIN_MAKE CATKIN_BUILD_ARGS -DCATKIN_ENABLE_TESTING:BOOL=OFF)
  CreateCatkinWorkspace(ID mc_rtc_ws DIR "catkin_ws" CATKIN_BUILD)
endif()

AddProject(ndcurves
  GITHUB loco-3d/ndcurves
  GIT_TAG v1.1.5
  CMAKE_ARGS -DBUILD_PYTHON_INTERFACE:BOOL=OFF
  SKIP_TEST
  APT_PACKAGES libndcurves-dev
)

AddProject(state-observation
  GITHUB jrl-umi3218/state-observation
  GIT_TAG origin/master
  CMAKE_ARGS -DBUILD_STATE_OBSERVATION_TOOLS:BOOL=OFF
  APT_PACKAGES libstate-observation-dev
)

if(PYTHON_BINDING)
  AddProject(Eigen3ToPython
    GITHUB jrl-umi3218/Eigen3ToPython
    GIT_TAG origin/master
    CMAKE_ARGS -DPIP_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
    APT_PACKAGES python-eigen python3-eigen
  )
  list(APPEND SpaceVecAlg_DEPENDS Eigen3ToPython)
endif()

AddProject(SpaceVecAlg
  GITHUB jrl-umi3218/SpaceVecAlg
  GIT_TAG origin/master
  DEPENDS ${SpaceVecAlg_DEPENDS}
  APT_PACKAGES libspacevecalg-dev python-spacevecalg python3-spacevecalg
)

AddProject(sch-core
  GITHUB jrl-umi3218/sch-core
  GIT_TAG origin/master
  CMAKE_ARGS -DCMAKE_CXX_STANDARD=11
  APT_PACKAGES libsch-core-dev
)

if(PYTHON_BINDING)
  AddProject(sch-core-python
    GITHUB jrl-umi3218/sch-core-python
    GIT_TAG origin/master
    CMAKE_ARGS -DPIP_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
    DEPENDS sch-core SpaceVecAlg
    APT_PACKAGES python-sch-core python3-sch-core
  )
endif()

AddProject(RBDyn
  GITHUB jrl-umi3218/RBDyn
  GIT_TAG origin/master
  DEPENDS SpaceVecAlg
  APT_PACKAGES librbdyn-dev python-rbdyn python3-rbdyn
)

if(EMSCRIPTEN)
  set(USE_F2C_ARGS CMAKE_ARGS "-DUSE_F2C:BOOL=ON" "-DCMAKE_C_STANDARD_INCLUDE_DIRECTORIES=${CMAKE_INSTALL_PREFIX}/include")
else()
  set(USE_F2C_ARGS "")
endif()

AddProject(eigen-qld
  GITHUB jrl-umi3218/eigen-qld
  GIT_TAG origin/master
  NO_NINJA
  ${USE_F2C_ARGS}
  APT_PACKAGES libeigen-qld-dev python-eigen-qld python3-eigen-qld
)

AddProject(eigen-quadprog
  GITHUB jrl-umi3218/eigen-quadprog
  GIT_TAG origin/master
  NO_NINJA
  ${USE_F2C_ARGS}
  APT_PACKAGES libeigen-quadprog-dev
)

if(WITH_LSSOL)
  if(USE_MC_RTC_APT_MIRROR)
    message(WARNING "LSSOL will not be used by mc-rtc if mc-rtc apt packages are used")
  endif()
  AddProject(eigen-lssol
    GITE multi-contact/eigen-lssol
    GIT_TAG origin/master
    NO_NINJA
    ${USE_F2C_ARGS}
  )
endif()

set(Tasks_DEPENDS RBDyn eigen-qld sch-core)
if(WITH_LSSOL)
  list(APPEND Tasks_DEPENDS eigen-lssol)
endif()
if(PYTHON_BINDING)
  list(APPEND Tasks_DEPENDS sch-core-python)
endif()
AddProject(Tasks
  GITHUB jrl-umi3218/Tasks
  GIT_TAG origin/master
  DEPENDS ${Tasks_DEPENDS}
  APT_PACKAGES libtasks-qld-dev python-tasks python3-tasks
)

AddProject(lexls
  GITHUB jrl-umi3218/lexls
  GIT_TAG origin/master
  CMAKE_ARGS -DINSTALL_PDF_DOCUMENTATION:BOOL=OFF -DINSTALL_HTML_DOCUMENTATION:BOOL=OFF
  APT_PACKAGES liblexls-dev
)

if(WITH_LSSOL)
  set(tvm_EXTRA_DEPENDS eigen-lssol)
else()
  set(tvm_EXTRA_DEPENDS)
endif()

AddProject(tvm
  GITHUB jrl-umi3218/tvm
  GIT_TAG origin/master
  DEPENDS eigen-qld eigen-quadprog lexls ${tvm_EXTRA_DEPENDS}
  CMAKE_ARGS -DTVM_WITH_QLD:BOOL=ON -DTVM_WITH_QUADPROG:BOOL=ON -DTVM_WITH_LEXLS:BOOL=ON -DTVM_WITH_ROBOT:BOOL=OFF -DTVM_THOROUGH_TESTING:BOOL=OFF -DTVM_WITH_LSSOL:BOOL=${WITH_LSSOL}
  APT_PACKAGES libtvm-dev
)

if(NOT WITH_ROS_SUPPORT)
  set(MC_RTC_ROS_BRANCH origin/ROSFree)
else()
  set(MC_RTC_ROS_BRANCH origin/master)
endif()
AddCatkinProject(mc_rtc_data
  GITHUB jrl-umi3218/mc_rtc_data
  GIT_TAG ${MC_RTC_ROS_BRANCH}
  WORKSPACE data_ws
  APT_PACKAGES mc-rtc-data ros-${ROS_DISTRO}-mc-rtc-data
)

set(mc_rtc_DEPENDS tvm Tasks mc_rtc_data ndcurves state-observation)
if(WITH_ROS_SUPPORT)
  AddCatkinProject(mc_rtc_msgs
    GITHUB jrl-umi3218/mc_rtc_msgs
    GIT_TAG origin/master
    WORKSPACE data_ws
    APT_PACKAGES ros-${ROS_DISTRO}-mc-rtc-msgs
  )
  list(APPEND mc_rtc_DEPENDS mc_rtc_msgs)
endif()

if(TARGET spdlog)
  list(APPEND mc_rtc_DEPENDS spdlog)
endif()
if(NOT DEFINED MC_LOG_UI_PYTHON_EXECUTABLE)
  set(MC_LOG_UI_PYTHON_EXECUTABLE ${MC_RTC_SUPERBUILD_DEFAULT_PYTHON})
endif()
if(WITH_ROS_SUPPORT)
  set(MC_RTC_ROS_OPTION "-DDISABLE_ROS=OFF")
else()
  set(MC_RTC_ROS_OPTION "-DDISABLE_ROS=ON")
endif()
if(EMSCRIPTEN)
  set(MC_RTC_EXTRA_OPTIONS -DMC_RTC_BUILD_STATIC=ON -DMC_RTC_DISABLE_NETWORK=ON -DMC_RTC_DISABLE_STACKTRACE=ON -DJVRC_DESCRIPTION_PATH=/assets/jvrc_description -DMC_ENV_DESCRIPTION_PATH=/assets/mc_env_description -DMC_INT_OBJ_DESCRIPTION_PATH=/assets/mc_int_obj_description)
else()
  set(MC_RTC_EXTRA_OPTIONS)
endif()
AddProject(mc_rtc
  GITHUB jrl-umi3218/mc_rtc
  GIT_TAG origin/master
  CMAKE_ARGS -DMC_LOG_UI_PYTHON_EXECUTABLE=${MC_LOG_UI_PYTHON_EXECUTABLE} ${MC_RTC_ROS_OPTION} ${MC_RTC_EXTRA_OPTIONS}
  DEPENDS ${mc_rtc_DEPENDS}
  APT_PACKAGES libmc-rtc-dev mc-rtc-utils python-mc-rtc python3-mc-rtc ros-${ROS_DISTRO}-mc-rtc-plugin
)

if(WITH_ROS_SUPPORT AND NOT ROS_IS_ROS2)
  AddCatkinProject(mc_rtc_ros
    GITHUB jrl-umi3218/mc_rtc_ros
    GIT_TAG origin/master
    WORKSPACE mc_rtc_ws
    DEPENDS mc_rtc
    APT_PACKAGES ros-${ROS_DISTRO}-mc-rtc-plugin ros-${ROS_DISTRO}-mc-rtc-tools
  )
endif()

set(MC_STATE_OBSERVATION_DEPENDS mc_rtc)
set(MC_STATE_OBSERVATION_OPTIONS "-DWITH_ROS_OBSERVERS=OFF")

if(WITH_ROS_SUPPORT)
  AddProject(gram_savitzky_golay
    GITHUB arntanguy/gram_savitzky_golay
    GIT_TAG origin/master
    APT_PACKAGES libgram-savitzky-golay-dev
  )
  list(APPEND MC_STATE_OBSERVATION_DEPENDS gram_savitzky_golay)
  set(MC_STATE_OBSERVATION_OPTIONS "-DWITH_ROS_OBSERVERS=ON")
  AptInstall(ros-${ROS_DISTRO}-tf2-eigen)
endif()

AddProject(mc_state_observation
  GITHUB jrl-umi3218/mc_state_observation
  CMAKE_ARGS ${MC_STATE_OBSERVATION_OPTIONS}
  DEPENDS ${MC_STATE_OBSERVATION_DEPENDS}
  APT_PACKAGES mc-state-observation ros-${ROS_DISTRO}-mc-state-observation
)
