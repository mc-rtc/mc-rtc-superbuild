# Check if a given prefix requires sudo to write-to
function(PrefixRequireSudo PREFIX VAR_OUT)
  if(NOT EXISTS "${PREFIX}")
    execute_process(
      COMMAND ${CMAKE_COMMAND} -E make_directory ${PREFIX} OUTPUT_QUIET ERROR_QUIET
    )
  endif()
  set(TEST_FILE "${PREFIX}/${PROJECT_NAME}.writable")
  # Same as file(TOUCH ...) but ignores failure
  execute_process(
    COMMAND ${CMAKE_COMMAND} -E touch ${TEST_FILE} OUTPUT_QUIET ERROR_QUIET
  )
  if(NOT EXISTS ${TEST_FILE})
    find_program(SUDO_CMD sudo)
    if(NOT SUDO_CMD)
      message(
        FATAL_ERROR
          "sudo is not installed on this system and the install prefix (${PREFIX}) is not writable by the current user.
  You can try the following solutions:
      - Choose a different installation prefix;
      - Install sudo;
      - Fix the permissions and try again;"
      )
    endif()
    set(${VAR_OUT}
        TRUE
        PARENT_SCOPE
    )
    message("-- Use sudo for install: ${SUDO_CMD}")
  else()
    file(REMOVE ${TEST_FILE})
    set(${VAR_OUT}
        FALSE
        PARENT_SCOPE
    )
  endif()
endfunction()

# Check if the install prefix is writable by the current user and set SUDO_CMD
# accordingly
PrefixRequireSudo(${CMAKE_INSTALL_PREFIX} USE_SUDO)
