# Check if the install prefix is writable by the current user and set SUDO_CMD accordingly
set(USE_SUDO FALSE)
if(NOT EXISTS "${CMAKE_INSTALL_PREFIX}")
  execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_INSTALL_PREFIX} OUTPUT_QUIET ERROR_QUIET)
endif()
set(TEST_FILE "${CMAKE_INSTALL_PREFIX}/${PROJECT_NAME}.writable")
# Same as file(TOUCH ...) but ignores failure
execute_process(COMMAND ${CMAKE_COMMAND} -E touch ${TEST_FILE} OUTPUT_QUIET ERROR_QUIET)
if(NOT EXISTS ${TEST_FILE})
  find_program(SUDO_CMD sudo)
  if(NOT SUDO_CMD)
    message(FATAL_ERROR "sudo is not installed on this system and the install prefix (${CMAKE_INSTALL_PREFIX}) is not writable by the current user.
You can try the following solutions:
    - Choose a different installation prefix;
    - Install sudo;
    - Fix the permissions and try again;")
  endif()
  set(USE_SUDO TRUE)
  message("-- Use sudo for install: ${SUDO_CMD}")
else()
  file(REMOVE ${TEST_FILE})
endif()
