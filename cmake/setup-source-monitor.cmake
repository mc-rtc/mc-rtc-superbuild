# This creates a source-monitor-${NAME} target
# The target is always out-dated and force a reconfigure if the project's content has been updated
function(SetupSourceMonitor NAME SOURCE_DIR)
  set(STAMP_DIR "${PROJECT_BINARY_DIR}/prefix/${NAME}/src/${NAME}-stamp/")
  add_custom_target(source-monitor-${NAME} ALL
    COMMAND
      "${CMAKE_COMMAND}"
        -DNAME=${NAME}
        -DSTAMP_DIR=${STAMP_DIR}
        -DSOURCE_DIR=${SOURCE_DIR}
        -P "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/scripts/source-monitor.cmake"
    VERBATIM
    COMMENT ""
  )
  add_dependencies(${NAME}-configure source-monitor-${NAME})
endfunction()
