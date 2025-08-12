if(NOT EXISTS "${BINARY_DIR}/to-src")
  execute_process(
    COMMAND ${CMAKE_COMMAND} -E create_symlink "${SOURCE_DIR}" "${BINARY_DIR}/to-src"
            COMMAND_ERROR_IS_FATAL ANY
  )
endif()
if(NOT EXISTS "${SOURCE_DIR}/build${BUILD_LINK_SUFFIX}")
  execute_process(
    COMMAND ${CMAKE_COMMAND} -E create_symlink "${BINARY_DIR}"
            "${SOURCE_DIR}/build${BUILD_LINK_SUFFIX}" COMMAND_ERROR_IS_FATAL ANY
  )
endif()
