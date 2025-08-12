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
  if(ROS_IS_ROS2)
    set(ENV{ROS_VERSION} "2")
    set(ENV{AMENT_PREFIX_PATH} "${DEV_DIR}:$ENV{AMENT_PREFIX_PATH}")
    set(ENV{COLCON_PREFIX_PATH} "${DEV_DIR}:$ENV{COLCON_PREFIX_PATH}")
    set(ENV{PYTHONPATH}
        "${DEV_DIR}/local/lib/python3.10/dist-packages:$ENV{PYTHONPATH}"
    )
  else()
    set(ENV{ROS_VERSION} "1")
    set(ENV{PKG_CONFIG_PATH} "${DEV_DIR}/lib/pkgconfig:$ENV{PKG_CONFIG_PATH}")
    set(ENV{ROS_PACKAGE_PATH} "${SRC_DIR}:$ENV{ROS_PACKAGE_PATH}")
  endif()
  set(ENV{CMAKE_PREFIX_PATH} "${DEV_DIR}:$ENV{CMAKE_PREFIX_PATH}")
  if(APPLE)
    set(ENV{DYLD_LIBRARY_PATH} "${DEV_DIR}/lib:$ENV{DYLD_LIBRARY_PATH}")
  else()
    set(ENV{LD_LIBRARY_PATH} "${DEV_DIR}/lib:$ENV{LD_LIBRARY_PATH}")
  endif()
  set(ENV{PYTHONPATH}
      "${DEV_DIR}/${ROS_WORKSPACE_INSTALL_PYTHON_DESTINATION}:$ENV{PYTHONPATH}"
  )
endfunction()

function(ConfigureSkipList ID)
  get_property(WKS_DIR GLOBAL PROPERTY CATKIN_WORKSPACE_${ID}_DIR)
  get_property(SKIPLIST_STAMP GLOBAL PROPERTY CATKIN_WORKSPACE_${ID}_SKIPLIST_STAMP)
  get_property(SKIPLIST_FILE GLOBAL PROPERTY CATKIN_WORKSPACE_${ID}_SKIPLIST_FILE)
  get_property(
    SKIPLIST_FILE_CACHE GLOBAL PROPERTY CATKIN_WORKSPACE_${ID}_SKIPLIST_FILE_CACHE
  )
  add_custom_command(
    OUTPUT "${SKIPLIST_STAMP}"
    COMMAND
      "${CMAKE_COMMAND}" -DWKS=${ID} -DWKS_DIR=${WKS_DIR}
      -DSKIPLIST_STAMP=${SKIPLIST_STAMP} -DSKIPLIST_FILE=${SKIPLIST_FILE_CACHE}
      -DROS_DISTRO=${ROS_DISTRO} -P
      ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/scripts/catkin-configure-skiplist.cmake
    DEPENDS "${SKIPLIST_FILE_CACHE}"
  )
endfunction()

# Creates a catkin workspace
#
# Options
# =======
#
# * ID <ID> Unique ID for the workspace, must follow the CMake's target naming rule
# * DIR <DIR> Folder where the workspace is created
# * CATKIN_MAKE Init/Build the workspace for/with catkin_make
# * CATKIN_BUILD Init/Build the workspace for/with catkin
# * CATKIN_BUILD_ARGS <args...> Arguments for catkin build
#
# CATKIN_MAKE/CATKIN_BUILD are mutually exclusive
#
function(CreateCatkinWorkspace)
  set(options CATKIN_MAKE CATKIN_BUILD)
  set(oneValueArgs ID DIR)
  set(multiValueArgs CATKIN_BUILD_ARGS)
  cmake_parse_arguments(
    CC_WORKSPACE_ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN}
  )
  if(CC_WORKSPACE_ARGS_CATKIN_MAKE AND CC_WORKSPACE_ARGS_CATKIN_BUILD)
    message(
      FATAL_ERROR
        "[CreateCatkinWorkspace] You must choose between CATKIN_MAKE AND CATKIN_BUILD"
    )
  endif()
  if(NOT CC_WORKSPACE_ARGS_ID)
    message(FATAL_ERROR "[CreateCatkinWorkspace] ID is required")
  endif()
  set(ID "${CC_WORKSPACE_ARGS_ID}")
  if(NOT CC_WORKSPACE_ARGS_DIR)
    message(FATAL_ERROR "[CreateCatkinWorkspace] DIR is required")
  endif()
  if(IS_ABSOLUTE "${CC_WORKSPACE_ARGS_DIR}")
    message(
      FATAL_ERROR "[CreateCatkinWorkspace] DIR must be relative to SOURCE_DESTINATION"
    )
  endif()
  set(DIR "${SOURCE_DESTINATION}/${CC_WORKSPACE_ARGS_DIR}")
  set(WORKSPACE_TYPE "make")
  if(CC_WORKSPACE_ARGS_CATKIN_BUILD)
    set(WORKSPACE_TYPE "build")
  endif()
  if(ROS_IS_ROS2)
    set(WORKSPACE_TYPE "colcon")
  endif()
  if(ROS_IS_ROS2)
    AppendROSWorkspace("${DIR}/install" "${DIR}/src")
  else()
    AppendROSWorkspace("${DIR}/devel" "${DIR}/src")
  endif()
  set(STAMP_DIR "${PROJECT_BINARY_DIR}/catkin-stamps/")
  getcommandprefix(COMMAND_PREFIX "${STAMP_DIR}/cmake-prefix.cmake")
  file(MAKE_DIRECTORY "${STAMP_DIR}")
  set(STAMP_FILE "${STAMP_DIR}/${ID}.init.stamp")
  add_custom_command(
    OUTPUT "${STAMP_FILE}"
    COMMAND
      ${COMMAND_PREFIX} "${CMAKE_COMMAND}" -DROS_IS_ROS2=${ROS_IS_ROS2}
      -DCATKIN_DIR=${DIR} -DWORKSPACE_TYPE=${WORKSPACE_TYPE} -P
      "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/scripts/init-catkin-workspace.cmake"
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

  handle_compiler_launcher(CC_WORKSPACE_ARGS_CATKIN_BUILD_ARGS)

  if(WORKSPACE_TYPE STREQUAL "make")
    set(BUILD_COMMAND
        ${COMMAND_PREFIX} catkin_make -C "${DIR}" -DCMAKE_BUILD_TYPE=$<CONFIG>
        ${CC_WORKSPACE_ARGS_CATKIN_BUILD_ARGS}
    )
    set(BUILD_COMMAND_DEPENDS)
  elseif(WORKSPACE_TYPE STREQUAL "build")
    set(BUILD_COMMAND
        ${COMMAND_PREFIX} "${CMAKE_COMMAND}" -E chdir "${DIR}" catkin build
        -DCMAKE_BUILD_TYPE=$<CONFIG> ${CC_WORKSPACE_ARGS_CATKIN_BUILD_ARGS}
    )

    set(SKIPLIST_FILE "${STAMP_DIR}/${ID}-skiplist.txt")
    set_property(
      GLOBAL PROPERTY CATKIN_WORKSPACE_${ID}_SKIPLIST_FILE "${SKIPLIST_FILE}"
    )
    file(REMOVE "${SKIPLIST_FILE}")
    file(TOUCH "${SKIPLIST_FILE}")
    set(SKIPLIST_FILE_CACHE "${STAMP_DIR}/${ID}-skiplist-cache.txt")
    set_property(
      GLOBAL PROPERTY CATKIN_WORKSPACE_${ID}_SKIPLIST_FILE_CACHE
                      "${SKIPLIST_FILE_CACHE}"
    )
    file(
      GENERATE
      OUTPUT "${SKIPLIST_FILE_CACHE}"
      INPUT "${SKIPLIST_FILE}"
    )

    set(SKIPLIST_STAMP_FILE "${STAMP_DIR}/${ID}-skiplist.stamp")
    set_property(
      GLOBAL PROPERTY CATKIN_WORKSPACE_${ID}_SKIPLIST_STAMP "${SKIPLIST_STAMP_FILE}"
    )

    add_custom_target(catkin-config-skiplist-${ID} DEPENDS "${SKIPLIST_STAMP_FILE}")
    add_dependencies(catkin-config-skiplist-${ID} catkin-init-${ID})
    set(BUILD_COMMAND_DEPENDS DEPENDS ${SKIPLIST_STAMP_FILE})
  else()
    # FIXME Add support for skiplist
    set(BUILD_COMMAND
        ${CMAKE_COMMAND} -E chdir ${DIR} ${COMMAND_PREFIX} colcon build --merge-install
        --cmake-args -DCMAKE_BUILD_TYPE=$<CONFIG>
        -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=ON ${CC_WORKSPACE_ARGS_CATKIN_BUILD_ARGS}
    )
  endif()
  set(STAMP_FILE "${STAMP_DIR}/${ID}.stamp")
  set_property(GLOBAL PROPERTY CATKIN_WORKSPACE_${ID}_STAMP "${STAMP_FILE}")
  # create workspace-level symlink for compile_commands.json
  if(LINK_COMPILE_COMMANDS)
    set(OPTIONAL_LINK_COMPILE_COMMANDS
        ${CMAKE_COMMAND} -DSOURCE_DIR=${DIR} -DBINARY_DIR="${DIR}/build" -P
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/scripts/link-compile-commands.cmake
    )
  else()
    set(OPTIONAL_LINK_COMPILE_COMMANDS "")
  endif()
  add_custom_command(
    OUTPUT "${STAMP_FILE}"
    COMMAND ${BUILD_COMMAND}
    COMMAND ${OPTIONAL_LINK_COMPILE_COMMANDS}
    COMMAND "${CMAKE_COMMAND}" -E touch "${STAMP_FILE}"
    COMMENT "Build catkin workspace ${ID} at ${DIR}" ${BUILD_COMMAND_DEPENDS}
  )
  add_custom_target(catkin-build-${ID} DEPENDS "${STAMP_FILE}")
  add_dependencies(catkin-build-${ID} catkin-init-${ID})

  add_custom_target(
    catkin-link-compile-commands-${ID}
    DEPENDS "${STAMP_FILE}"
    COMMAND echo "Finalizing catkin workspace ${ID}"
  )
  add_dependencies(catkin-link-compile-commands-${ID} catkin-build-${ID})
  # if(LINK_COMPILE_COMMANDS)
  # message(STATUS "LINK_COMPILE_COMMANDS is set, colcon will link compile_commands.json to ${DIR}/compile_commands.json")
  # add_custom_command(
  #     OUTPUT ${DIR}/compile_commands.json
  #     COMMAND
  #       ${CMAKE_COMMAND} -DSOURCE_DIR=${DIR} -DBINARY_DIR="${DIR}/build" -P
  #       ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/scripts/link-compile-commands.cmake
  #     DEPENDS "${STAMP_FILE}"
  #     COMMENT "Link compile_commands.json for ${ID} at ${DIR}"
  #   )
  #   add_custom_target(catkin-link-compile-commands-${ID} DEPENDS ${DIR}/compile_commands.json)
  #   add_dependencies(catkin-link-compile-commands-${ID} catkin-build-${ID})
  # endif()
  cmake_language(
    EVAL CODE "
    cmake_language(DEFER CALL FinalizeCatkinWorkspace [[${ID}]])
  "
  )
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
  ensurevalidcatkinworkspace(${ID})
  if(NOT TARGET catkin-config-skiplist-${ID})
    message(FATAL_ERROR "${ID} must be a catkin build workspace to use this feature")
  endif()
  get_property(SKIPLIST_FILE GLOBAL PROPERTY CATKIN_WORKSPACE_${ID}_SKIPLIST_FILE)
  file(APPEND "${SKIPLIST_FILE}" "${PKG}\n")
endfunction()

function(SetCatkinDependencies TARGET TARGET_DEPENDENCIES TARGET_WORKSPACE)
  get_property(CATKIN_WORKSPACES GLOBAL PROPERTY CATKIN_WORKSPACES)
  foreach(WKS ${CATKIN_WORKSPACES})
    get_property(WKS_TARGETS GLOBAL PROPERTY CATKIN_WORKSPACE_${WKS})
    foreach(TGT ${TARGET_DEPENDENCIES})
      list(FIND WKS_TARGETS "${TGT}" TMP)
      if(TMP GREATER_EQUAL 0 AND NOT "${WKS}" STREQUAL "${TARGET_WORKSPACE}")
        add_dependencies(${TARGET}-configure catkin-build-${WKS})
        set_property(GLOBAL PROPERTY CATKIN_WORKSPACE_${WKS}_IS_LEAF FALSE)
      endif()
    endforeach()
  endforeach()
endfunction()

function(FinalizeCatkinWorkspace WKS)
  get_property(IS_LEAF GLOBAL PROPERTY CATKIN_WORKSPACE_${WKS}_IS_LEAF)
  if(TARGET catkin-config-skiplist-${WKS})
    ConfigureSkipList(${WKS})
  endif()
  if(IS_LEAF)
    add_custom_target(force-catkin-build-${WKS} ALL)
    add_dependencies(force-catkin-build-${WKS} catkin-build-${WKS})
  endif()
endfunction()
