# Call a command with an environment prefix
file(READ ${CMAKE_PREFIX_FILE} CMAKE_PREFIX)
set(CMAKE_COMMAND_WITH_PREFIX ${CMAKE_PREFIX})
set(EXTRA_ARGS FALSE)
foreach(ARGC RANGE ${CMAKE_ARGC})
  set(ARGV ${CMAKE_ARGV${ARGC}})
  if(EXTRA_ARGS)
    # Enclose arguments that have space in them if there are no quotes This assumes the
    # arguments are already well quoted otherwise which should be the case
    if("${ARGV}" MATCHES " " AND NOT "${ARGV}" MATCHES "\"")
      string(APPEND CMAKE_COMMAND_WITH_PREFIX " \"${CMAKE_ARGV${ARGC}}\"")
    else()
      string(APPEND CMAKE_COMMAND_WITH_PREFIX " ${CMAKE_ARGV${ARGC}}")
    endif()
  endif()
  if("${ARGV}" STREQUAL "--")
    set(EXTRA_ARGS TRUE)
  endif()
endforeach()
string(REPLACE ";" "\\;" CMAKE_COMMAND_WITH_PREFIX "${CMAKE_COMMAND_WITH_PREFIX}")
separate_arguments(
  CMAKE_COMMAND_WITH_PREFIX NATIVE_COMMAND ${CMAKE_COMMAND_WITH_PREFIX}
)
execute_process(COMMAND ${CMAKE_COMMAND_WITH_PREFIX} COMMAND_ERROR_IS_FATAL ANY)
