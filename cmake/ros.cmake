include(cmake/command-prefix.cmake)

set_property(GLOBAL PROPERTY CATKIN_WORKSPACES)
set_property(GLOBAL PROPERTY PREVIOUS_CATKIN_WORKSPACE)

# A function to mimic source $WORKSPACE/devel/setup.bash in CMake
function(AppendROSWorkspace DEV_DIR SRC_DIR)
  if("$ENV{CMAKE_PREFIX_PATH}" MATCHES "${DEV_DIR}")
    return()
  endif()
  if("$ENV{ROS_PARALLEL_JOBS}" STREQUAL "")
    include(ProcessorCount)
    ProcessorCount(N)
    set(ENV{ROS_PARALLEL_JOBS} "-j${N} -l${N}")
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
  if(IS_ABSOLUTE "${CC_WORKSPACE_ARGS_DIR}")
    message(FATAL_ERROR "[CreateCatkinWorkspace] DIR must be relative to SOURCE_DESTINATION")
  endif()
  set(DIR "${SOURCE_DESTINATION}/${CC_WORKSPACE_ARGS_DIR}")
  set(use_catkin_make TRUE)
  if(CC_WORKSPACE_ARGS_CATKIN_BUILD)
    set(use_catkin_make FALSE)
  endif()
  if(use_catkin_make)
    set(WORKSPACE_TYPE "make")
  else()
    set(WORKSPACE_TYPE "build")
  endif()
  AppendROSWorkspace("${DIR}/devel" "${DIR}/src")
  GetCommandPrefix(COMMAND_PREFIX)
  set(STAMP_DIR "${PROJECT_BINARY_DIR}/catkin-stamps/")
  file(MAKE_DIRECTORY "${STAMP_DIR}")
  set(STAMP_FILE "${STAMP_DIR}/${ID}.init.stamp")
  add_custom_command(
    OUTPUT "${STAMP_FILE}"
    BYPRODUCTS "${DIR}/devel/setup.sh"
    COMMAND ${COMMAND_PREFIX} "${CMAKE_COMMAND}" -DCATKIN_DIR=${DIR} -DWORKSPACE_TYPE=${WORKSPACE_TYPE} -P "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/scripts/init-catkin-workspace.cmake"
    COMMAND "${CMAKE_COMMAND}" -E touch "${STAMP_FILE}"
    COMMENT "Initializing catkin workspace in ${DIR}"
  )
  add_custom_target(catkin-init-${ID} DEPENDS "${STAMP_FILE}")
  get_property(PREVIOUS_WORKSPACE GLOBAL PROPERTY PREVIOUS_CATKIN_WORKSPACE)
  if(NOT "${PREVIOUS_WORKSPACE}" STREQUAL "")
    add_dependencies(catkin-init-${ID} catkin-init-${PREVIOUS_WORKSPACE})
  endif()
  set_property(GLOBAL PROPERTY PREVIOUS_CATKIN_WORKSPACE "${ID}")
  set_property(GLOBAL APPEND PROPERTY CATKIN_WORKSPACES "${ID}")
  set_property(GLOBAL PROPERTY CATKIN_WORKSPACE_${ID})
  set_property(GLOBAL PROPERTY CATKIN_WORKSPACE_${ID}_DIR "${DIR}")
  set_property(GLOBAL PROPERTY CATKIN_WORKSPACE_${ID}_IS_LEAF TRUE)
  if(use_catkin_make)
    set(BUILD_COMMAND ${COMMAND_PREFIX} catkin_make -C "${DIR}" -DCMAKE_BUILD_TYPE=$<CONFIG> ${CC_WORKSPACE_ARGS_CATKIN_BUILD_ARGS})
    set(BUILD_COMMAND_DEPENDS)
  else()
    set(BUILD_COMMAND ${COMMAND_PREFIX} "${CMAKE_COMMAND}" -E chdir "${DIR}" catkin build -DCMAKE_BUILD_TYPE=$<CONFIG> ${CC_WORKSPACE_ARGS_CATKIN_BUILD_ARGS})
    set_property(GLOBAL PROPERTY CATKIN_WORKSPACE_${ID}_SKIPLIST)
    set(SKIPLIST_STAMP_FILE "${STAMP_DIR}/${ID}-skiplist.stamp")
    set_property(GLOBAL PROPERTY CATKIN_WORKSPACE_${ID}_SKIPLIST_STAMP "${SKIPLIST_STAMP_FILE}")
    add_custom_target(catkin-config-skiplist-${ID} DEPENDS "${SKIPLIST_STAMP_FILE}")
    add_dependencies(catkin-config-skiplist-${ID} catkin-init-${ID})
    set(BUILD_COMMAND_DEPENDS DEPENDS ${SKIPLIST_STAMP_FILE})
  endif()
  set(STAMP_FILE "${STAMP_DIR}/${ID}.stamp")
  set_property(GLOBAL PROPERTY CATKIN_WORKSPACE_${ID}_STAMP "${STAMP_FILE}")
  add_custom_command(
    OUTPUT "${STAMP_FILE}"
    COMMAND ${BUILD_COMMAND}
    COMMAND "${CMAKE_COMMAND}" -E touch "${STAMP_FILE}"
    COMMENT "Build catkin workspace ${ID} at ${DIR}"
    ${BUILD_COMMAND_DEPENDS}
  )
  add_custom_target(catkin-build-${ID} DEPENDS "${STAMP_FILE}")
  add_dependencies(catkin-build-${ID} catkin-init-${ID})
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

function(AddPackageToCatkinSkiplist ID PKG)
  EnsureValidCatkinWorkspace(${ID})
  if(NOT TARGET catkin-config-skiplist-${ID})
    message(FATAL_ERROR "${ID} must be a catkin build workspace to use this feature")
  endif()
  set_property(GLOBAL APPEND PROPERTY CATKIN_WORKSPACE_${ID}_SKIPLIST ${PKG})
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
    if(TARGET catkin-config-skiplist-${WKS})
      get_property(WKS_DIR GLOBAL PROPERTY CATKIN_WORKSPACE_${WKS}_DIR)
      get_property(SKIPLIST_STAMP GLOBAL PROPERTY CATKIN_WORKSPACE_${WKS}_SKIPLIST_STAMP)
      get_property(SKIPLIST GLOBAL PROPERTY CATKIN_WORKSPACE_${WKS}_SKIPLIST)
      list(LENGTH SKIPLIST N_SKIPLIST)
      set(CONFIG_SKIPLIST_COMMAND "${CMAKE_COMMAND}" -E chdir "${WKS_DIR}")
      if(N_SKIPLIST EQUAL 0)
        set(CONFIG_SKIPLIST_COMMAND ${CONFIG_SKIPLIST_COMMAND} catkin config --no-skiplist)
        set(CONFIG_SKIPLIST_COMMAND_COMMENT "Clearing skiplist for ${WKS}")
      else()
        set(CONFIG_SKIPLIST_COMMAND ${CONFIG_SKIPLIST_COMMAND} catkin config --skiplist ${SKIPLIST})
        list(JOIN SKIPLIST " " SKIPLIST_STR)
        set(CONFIG_SKIPLIST_COMMAND_COMMENT "Set skiplist for ${WKS}: ${SKIPLIST_STR}")
      endif()
      add_custom_command(
        OUTPUT "${SKIPLIST_STAMP}"
        COMMAND ${CONFIG_SKIPLIST_COMMAND}
        COMMAND "${CMAKE_COMMAND}" -E touch "${SKIPLIST_STAMP}"
        COMMENT ${CONFIG_SKIPLIST_COMMAND_COMMENT}
      )
    endif()
    if(IS_LEAF)
      add_custom_target(force-catkin-build-${WKS} ALL)
      add_dependencies(force-catkin-build-${WKS} catkin-build-${WKS})
    endif()
  endforeach()
endfunction()
