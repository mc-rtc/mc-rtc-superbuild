include(cmake/command-prefix.cmake)

set_property(GLOBAL PROPERTY CATKIN_WORKSPACES)

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

# Creates a catkin workspace
#
# Options
# =======
#
# - ID <ID> Unique ID for the workspace, must follow the CMake's target naming rule
# - DIR <DIR> Folder where the workspace is created
# - CATKIN_MAKE Init/Build the workspace for/with catkin_make
# - CATKIN_BUILD Init/Build the workspace for/with catkin
# - CATKIN_BUILD_ARGS <args...> Arguments for catkin build
#
# CATKIN_MAKE/CATKIN_BUILD are mutually exclusive
#
function(CreateCatkinWorkspace)
  set(options CATKIN_MAKE CATKIN_BUILD)
  set(oneValueArgs ID DIR)
  set(multiValueArgs CATKIN_BUILD_ARGS)
  cmake_parse_arguments(CC_WORKSPACE_ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
  if(CC_WORKSPACE_ARGS_CATKIN_MAKE AND CC_WORKSPACE_ARGS_CATKIN_BUILD)
    message(FATAL_ERROR "[CreateCatkinWorkspace] You must choose between CATKIN_MAKE AND CATKIN_BUILD")
  endif()
  if(NOT CC_WORKSPACE_ARGS_ID)
    message(FATAL_ERROR "[CreateCatkinWorkspace] ID is required")
  endif()
  set(ID "${CC_WORKSPACE_ARGS_ID}")
  if(NOT CC_WORKSPACE_ARGS_DIR)
    message(FATAL_ERROR "[CreateCatkinWorkspace] DIR is required")
  endif()
  set(DIR "${CC_WORKSPACE_ARGS_DIR}")
  set(use_catkin_make TRUE)
  if(CC_WORKSPACE_ARGS_CATKIN_BUILD)
    set(use_catkin_make FALSE)
  endif()
  file(MAKE_DIRECTORY "${DIR}/src")
  if(use_catkin_make)
    if(NOT EXISTS "${DIR}/src/CMakeLists.txt")
      execute_process(
        COMMAND catkin_init_workspace
        WORKING_DIRECTORY "${DIR}/src"
        COMMAND_ERROR_IS_FATAL ANY
      )
    endif()
    if(NOT EXISTS "${DIR}/devel/setup.bash")
      execute_process(
        COMMAND catkin_make -C "${DIR}"
        COMMAND_ERROR_IS_FATAL ANY
      )
    endif()
  else()
    if(NOT EXISTS "${DIR}/.catkin_tools")
      execute_process(
        COMMAND catkin init
        WORKING_DIRECTORY "${DIR}"
        COMMAND_ERROR_IS_FATAL ANY
      )
    endif()
    if(NOT EXISTS "${DIR}/devel/setup.bash")
      execute_process(
        COMMAND catkin build
        WORKING_DIRECTORY "${DIR}"
        COMMAND_ERROR_IS_FATAL ANY
      )
    endif()
  endif()
  set_property(GLOBAL APPEND PROPERTY CATKIN_WORKSPACES "${ID}")
  set_property(GLOBAL PROPERTY CATKIN_WORKSPACE_${ID})
  set_property(GLOBAL PROPERTY CATKIN_WORKSPACE_${ID}_DIR "${DIR}")
  set_property(GLOBAL PROPERTY CATKIN_WORKSPACE_${ID}_IS_LEAF TRUE)
  AppendROSWorkspace("${DIR}/devel" "${DIR}/src")
  GetCommandPrefix(COMMAND_PREFIX)
  if(use_catkin_make)
    set(BUILD_COMMAND ${COMMAND_PREFIX} catkin_make -C "${DIR}" -DCMAKE_BUILD_TYPE=$<CONFIG>)
  else()
    set(BUILD_COMMAND ${COMMAND_PREFIX} "${CMAKE_COMMAND}" -E chdir "${DIR}" catkin build ${CC_WORKSPACE_ARGS_CATKIN_BUILD_ARGS})
  endif()
  set(STAMP_DIR "${PROJECT_BINARY_DIR}/catkin-stamps/")
  set(STAMP_FILE "${STAMP_DIR}/${ID}.stamp")
  set_property(GLOBAL PROPERTY CATKIN_WORKSPACE_${ID}_STAMP "${STAMP_FILE}")
  file(MAKE_DIRECTORY "${STAMP_DIR}")
  add_custom_command(
    OUTPUT "${STAMP_FILE}"
    COMMAND ${BUILD_COMMAND}
    COMMAND "${CMAKE_COMMAND}" -E touch "${STAMP_FILE}"
    COMMENT "Build catkin workspace ${ID} at ${DIR}"
  )
  add_custom_target(catkin-build-${ID} DEPENDS "${STAMP_FILE}")
endfunction()

function(EnsureValidCatkinWorkspace ID)
  get_property(CATKIN_WORKSPACES GLOBAL PROPERTY CATKIN_WORKSPACES)
  foreach(WKS ${CATKIN_WORKSPACES})
    if(WKS STREQUAL ${ID})
      return()
    endif()
  endforeach()
  message(FATAL_ERROR "${ID} is not a valid catkin workspace id")
endfunction()

function(SetCatkinDependencies TARGET TARGET_DEPENDENCIES TARGET_WORKSPACE)
  get_property(CATKIN_WORKSPACES GLOBAL PROPERTY CATKIN_WORKSPACES)
  foreach(WKS ${CATKIN_WORKSPACES})
    get_property(WKS_TARGETS GLOBAL PROPERTY CATKIN_WORKSPACE_${WKS})
    foreach(TGT ${TARGET_DEPENDENCIES})
      list(FIND WKS_TARGETS "${TGT}" TMP)
      if(TMP GREATER_EQUAL 0 AND NOT "${WKS}" STREQUAL "${TARGET_WORKSPACE}")
        add_dependencies(${TARGET} catkin-build-${WKS})
        set_property(GLOBAL PROPERTY CATKIN_WORKSPACE_${WKS}_IS_LEAF FALSE)
      endif()
    endforeach()
  endforeach()
endfunction()

function(FinalizeCatkinWorkspaces)
  get_property(CATKIN_WORKSPACES GLOBAL PROPERTY CATKIN_WORKSPACES)
  foreach(WKS ${CATKIN_WORKSPACES})
    get_property(IS_LEAF GLOBAL PROPERTY CATKIN_WORKSPACE_${WKS}_IS_LEAF)
    if(IS_LEAF)
      add_custom_target(force-catkin-build-${WKS} ALL)
      add_dependencies(force-catkin-build-${WKS} catkin-build-${WKS})
    endif()
  endforeach()
endfunction()
