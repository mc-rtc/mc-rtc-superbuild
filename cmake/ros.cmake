# A function to mimic source $WORKSPACE/devel/setup.bash in CMake
function(AppendROSWorkspace DEV_DIR SRC_DIR)
  if("$ENV{CMAKE_PREFIX_PATH}" MATCHES "${DEV_DIR}")
    return()
  endif()
  set(ENV{CMAKE_PREFIX_PATH} "${DEV_DIR}:$ENV{CMAKE_PREFIX_PATH}")
  if(APPLE)
    set(ENV{DYLD_LIBRARY_PATH} "${DEV_DIR}/lib:$ENV{DYLD_LIBRARY_PATH}")
  else()
    set(ENV{LD_LIBRARY_PATH} "${DEV_DIR}/lib:$ENV{LD_LIBRARY_PATH}")
  endif()
  set(ENV{PKG_CONFIG_PATH} "${DEV_DIR}/lib/pkgconfig:$ENV{PKG_CONFIG_PATH}")
  set(ENV{ROS_PACKAGE_PATH} "${SRC_DIR}:$ENV{ROS_PACKAGE_PATH}")
  if(EXISTS "${DEV_DIR}/lib/python3/dist-packages")
    set(ENV{PYTHONPATH} "${DEV_DIR}/lib/python3/dist-packages:$ENV{PYTHONPATH}")
  else()
    set(ENV{PYTHONPATH} "${DEV_DIR}/lib/python2.7/dist-packages:$ENV{PYTHONPATH}")
  endif()
endfunction()

# catkin_make in a workspace
function(MakeCatkinWorkspace DIR)
  execute_process(
    COMMAND catkin_make -C "${DIR}"
    COMMAND_ERROR_IS_FATAL ANY
  )
endfunction()

# Creates a catkin workspace
function(CreateCatkinWorkspace DIR)
  file(MAKE_DIRECTORY "${DIR}/src")
  if(NOT EXISTS "${DIR}/src/CMakeLists.txt")
    execute_process(
      COMMAND catkin_init_workspace
      WORKING_DIRECTORY "${DIR}/src"
      COMMAND_ERROR_IS_FATAL ANY
    )
  endif()
  if(NOT EXISTS "${DIR}/devel/setup.bash")
    MakeCatkinWorkspace("${DIR}")
  endif()
  AppendROSWorkspace("${DIR}/devel" "${DIR}/src")
endfunction()
