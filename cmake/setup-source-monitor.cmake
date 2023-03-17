# This creates a source-monitor-${NAME} target
# The target is always out-dated and force a reconfigure if the project's content has been updated
function(SetupSourceMonitor NAME SOURCE_DIR)
  set(STAMP_DIR "${PROJECT_BINARY_DIR}/prefix/${NAME}/src/${NAME}-stamp/")
  if(CMAKE_CONFIGURATION_TYPES)
    set(CONFIGURE_STAMP "${STAMP_DIR}/$<CONFIG>/${NAME}-configure")
  else()
    set(CONFIGURE_STAMP "${STAMP_DIR}/${NAME}-configure")
  endif()
  add_custom_target(source-monitor-${NAME} ALL
    COMMAND
      "${CMAKE_COMMAND}"
        -DNAME=${NAME}
        -DSTAMP_DIR=${STAMP_DIR}
        -DCONFIGURE_STAMP=${CONFIGURE_STAMP}
        -DSOURCE_DIR=${SOURCE_DIR}
        -P "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/scripts/source-monitor.cmake"
    VERBATIM
    COMMENT ""
  )
  add_dependencies(${NAME} source-monitor-${NAME})
  add_dependencies(${NAME}-configure source-monitor-${NAME})
  if(TARGET ${NAME}-submodule-update)
    add_dependencies(source-monitor-${NAME} ${NAME}-submodule-update)
  endif()
endfunction()
