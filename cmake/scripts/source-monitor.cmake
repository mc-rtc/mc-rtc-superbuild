cmake_minimum_required(VERSION 3.20)

# List all files in the source directory, except the .git folder
file(GLOB_RECURSE SOURCES "${SOURCE_DIR}/*")
list(FILTER SOURCES EXCLUDE REGEX "${SOURCE_DIR}/.*/?.git/")
list(FILTER SOURCES EXCLUDE REGEX "${SOURCE_DIR}/.*/?.git$")

# Filter out symbolic links
set(SOURCES_SYMLINKS)
set(LIST_I 0)
set(MUST_REMOVE OFF)
foreach(SOURCE ${SOURCES})
  if(IS_SYMLINK "${SOURCE}")
    list(APPEND SOURCES_SYMLINKS ${LIST_I})
    set(MUST_REMOVE ON)
  endif()
  math(EXPR LIST_I "${LIST_I} + 1")
endforeach()
if(MUST_REMOVE)
  list(REMOVE_AT SOURCES ${SOURCES_SYMLINKS})
endif()

# Also remove files that are ignored by git
execute_process(
  COMMAND git status --porcelain --ignored
  WORKING_DIRECTORY "${SOURCE_DIR}"
  OUTPUT_VARIABLE IGNORED_SOURCES
  ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE
)
execute_process(
  COMMAND git submodule foreach --recursive
          "git status --porcelain --ignored |sed -e\"s@\\!\\! @\\!\\! $displaypath/@\""
  WORKING_DIRECTORY "${SOURCE_DIR}"
  OUTPUT_VARIABLE IGNORED_SOURCES_SUBMODULE
  ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE
)
set(IGNORED_SOURCES "${IGNORED_SOURCES}\n${IGNORED_SOURCES_SUBMODULE}")
string(REPLACE "\n" ";" IGNORED_SOURCES "${IGNORED_SOURCES}")
list(FILTER IGNORED_SOURCES INCLUDE REGEX "^!! ")
list(TRANSFORM IGNORED_SOURCES REPLACE "^!! " "")
list(TRANSFORM IGNORED_SOURCES PREPEND "${SOURCE_DIR}/")
list(LENGTH IGNORED_SOURCES IGNORED_SOURCES_LENGTH)
foreach(IGNORE_SRC IN_LIST ${IGNORED_SOURCES})
  if(IS_DIRECTORY ${IGNORE_SRC})
    list(FILTER SOURCES EXCLUDE REGEX "${IGNORE_SRC}")
  else()
    list(REMOVE_ITEM SOURCES ${IGNORE_SRC})
  endif()
endforeach()

list(LENGTH SOURCES SOURCES_LENGTH)

set(SAVED_SOURCES "${STAMP_DIR}/${NAME}-source-monitor.sources")
set(SAVED_TIMESTAMPS "${STAMP_DIR}/${NAME}-source-monitor.timestamps")

function(_PutSourceInformationInCache NAME SOURCES)
  set(START_I 0)
  set(SOURCES_TIMESTAMP)
  list(LENGTH SOURCES SOURCES_LENGTH)
  while(START_I LESS ${SOURCES_LENGTH})
    list(GET SOURCES ${START_I} SOURCE)
    file(TIMESTAMP "${SOURCE}" SOURCE_TIMESTAMP UTC)
    list(APPEND SOURCES_TIMESTAMP "${SOURCE_TIMESTAMP}")
    math(EXPR START_I "${START_I} + 1")
  endwhile()
  if(EXISTS "${SAVED_SOURCES}")
    file(RENAME "${SAVED_SOURCES}" "${SAVED_SOURCES}.before")
    file(RENAME "${SAVED_TIMESTAMPS}" "${SAVED_TIMESTAMPS}.before")
  endif()
  file(WRITE "${SAVED_SOURCES}" "${SOURCES}")
  file(WRITE "${SAVED_TIMESTAMPS}" "${SOURCES_TIMESTAMP}")
endfunction()

if(EXISTS "${SAVED_SOURCES}")
  file(READ "${SAVED_SOURCES}" PREVIOUS_SOURCES)
  list(LENGTH PREVIOUS_SOURCES PREVIOUS_SOURCES_LENGTH)
else()
  set(PREVIOUS_SOURCES)
  set(PREVIOUS_SOURCES_LENGTH 0)
endif()

# This should be the case after the first clone, no need to trigger a build then
if(${PREVIOUS_SOURCES_LENGTH} EQUAL 0 AND NOT ${SOURCES_LENGTH} EQUAL 0)
  _PutSourceInformationInCache(${NAME} "${SOURCES}")
  return()
endif()

# Should only be the case on the first run, no sources have appeared yet
if(${SOURCES_LENGTH} EQUAL 0)
  file(REMOVE "${CONFIGURE_STAMP}")
  return()
endif()

# At this point both SOURCES and PREVIOUS_SOURCES have files in them Let's compare them
if(NOT ${SOURCES_LENGTH} EQUAL ${PREVIOUS_SOURCES_LENGTH})
  # Remove the configure stamp because the list of sources has changed
  message("-- Will rebuild ${NAME} because the list of sources changed")
  file(REMOVE "${CONFIGURE_STAMP}")
  _PutSourceInformationInCache(${NAME} "${SOURCES}")
  return()
endif()

file(READ "${SAVED_TIMESTAMPS}" PREVIOUS_SOURCES_TIMESTAMP)
set(LIST_I 0)
while(LIST_I LESS ${SOURCES_LENGTH})
  list(GET SOURCES ${LIST_I} SOURCE)
  list(GET PREVIOUS_SOURCES ${LIST_I} PREVIOUS_SOURCE)
  if(NOT "${SOURCE}" STREQUAL "${PREVIOUS_SOURCE}")
    # Remove the configure stamp because the list of sources has changed
    message("-- Will rebuild ${NAME} because the list of sources changed")
    file(REMOVE "${CONFIGURE_STAMP}")
    _PutSourceInformationInCache(${NAME} "${SOURCES}")
    return()
  endif()
  file(TIMESTAMP "${SOURCE}" SOURCE_TIMESTAMP UTC)
  list(GET PREVIOUS_SOURCES_TIMESTAMP ${LIST_I} PREVIOUS_SOURCE_TIMESTAMP)
  if("${SOURCE_TIMESTAMP}" STREQUAL "" OR "${SOURCE_TIMESTAMP}" STRGREATER
                                          "${PREVIOUS_SOURCE_TIMESTAMP}"
  )
    # Remove the configure stamp because a source has been updated"
    message("-- Will rebuild ${NAME} because ${SOURCE} was updated")
    file(REMOVE "${CONFIGURE_STAMP}")
    _PutSourceInformationInCache(${NAME} "${SOURCES}")
    return()
  endif()
  list(APPEND SOURCES_TIMESTAMP "${TIMESTAMP}")
  math(EXPR LIST_I "${LIST_I} + 1")
endwhile()
# No changes detected
