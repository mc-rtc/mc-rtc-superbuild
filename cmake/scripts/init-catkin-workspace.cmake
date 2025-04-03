cmake_minimum_required(VERSION 3.20)

file(MAKE_DIRECTORY "${CATKIN_DIR}/src")

if(NOT EXISTS "${CAKTIN_DIR}/.gitignore")
  file(
    WRITE "${CATKIN_DIR}/.gitignore"
    ".catkin_tools/*
.catkin_workspace
build/*
devel/*
install/*
logs/*
src/CMakeLists.txt"
  )
endif()

if(ROS_IS_ROS2)
  return()
endif()

if("${WORKSPACE_TYPE}" STREQUAL "make")
  set(INIT_COMMAND catkin_init_workspace)
  set(INIT_WORKDIR "${CATKIN_DIR}/src")
  set(INIT_GENERATE "${CATKIN_DIR}/src/CMakeLists.txt")
  if(EXISTS "${CATKIN_DIR}/.catkin_tools")
    message(
      FATAL_ERROR "It appears there's already a catkin build workspace in ${CATKIN_DIR}"
    )
  endif()
else()
  set(INIT_COMMAND catkin init)
  set(INIT_WORKDIR "${CATKIN_DIR}")
  set(INIT_GENERATE "${CATKIN_DIR}/.catkin_tools")
  if(EXISTS "${CATKIN_DIR}/src/CMakeLists.txt")
    message(
      FATAL_ERROR "It appears there's already a catkin_make workspace in ${CATKIN_DIR}"
    )
  endif()
endif()

if(NOT EXISTS "${INIT_GENERATE}")
  execute_process(
    COMMAND ${INIT_COMMAND} WORKING_DIRECTORY "${INIT_WORKDIR}" COMMAND_ERROR_IS_FATAL
                                              ANY
  )
endif()

if("${WORKSPACE_TYPE}" STREQUAL "make")
  set(INIT_COMMAND catkin_make -C "${CATKIN_DIR}")
else()
  set(INIT_COMMAND catkin build)
endif()

if(NOT EXISTS "${CATKIN_DIR}/devel/setup.sh")
  file(GLOB SRC_FILES "${CATKIN_DIR}/src/*")
  if("${WORKSPACE_TYPE}" STREQUAL "make")
    set(NFILES_IF_EMPTY 1)
  else()
    set(NFILES_IF_EMPTY 0)
  endif()
  list(LENGTH SRC_FILES NFILES)
  if(NFILES EQUAL ${NFILES_IF_EMPTY})
    execute_process(
      COMMAND ${INIT_COMMAND} WORKING_DIRECTORY "${CATKIN_DIR}" COMMAND_ERROR_IS_FATAL
                                                ANY
    )
  endif()
endif()
