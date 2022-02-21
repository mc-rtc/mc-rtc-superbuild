if(NOT EXISTS "${BINARY_DIR}/compile_commands.json")
  return()
endif()
execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink "${BINARY_DIR}/compile_commands.json" "${SOURCE_DIR}/compile_commands.json" COMMAND_ERROR_IS_FATAL ANY)
