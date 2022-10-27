# How many times we retry before giving up
set(RETRY_COUNT 5)
# How much time (seconds) we wait between attempts
set(RETRY_WAIT 5)

if(GIT_TAG MATCHES "^origin/(.*)")
  set(GIT_TAG_IS_TAG OFF)
  string(REGEX REPLACE "^origin/" "" GIT_TAG "${GIT_TAG}")
else()
  set(GIT_TAG_IS_TAG ON)
endif()

if("${OPERATION}" STREQUAL "init")
  if(EXISTS "${SOURCE_DESTINATION}/${TARGET_FOLDER}/.git")
    return()
  endif()
  if(EXISTS "${SOURCE_DESTINATION}/${TARGET_FOLDER}")
    file(REMOVE_RECURSE "${SOURCE_DESTINATION}/${TARGET_FOLDER}")
  endif()
  set(BRANCH_OPTION -b ${GIT_TAG})
  if(GIT_TAG_IS_TAG)
    set(BRANCH_OPTION)
  endif()
  set(GIT_COMMAND git submodule add ${BRANCH_OPTION} ${GIT_REPOSITORY} "${TARGET_FOLDER}")
elseif("${OPERATION}" STREQUAL "update")
  execute_process(COMMAND
    git submodule set-url ${TARGET_FOLDER} ${GIT_REPOSITORY}
    WORKING_DIRECTORY "${SOURCE_DESTINATION}"
    COMMAND_ERROR_IS_FATAL ANY
  )
  if(NOT GIT_TAG_IS_TAG)
    execute_process(COMMAND
      git submodule set-branch --branch ${GIT_TAG} "${TARGET_FOLDER}"
      WORKING_DIRECTORY "${SOURCE_DESTINATION}"
      COMMAND_ERROR_IS_FATAL ANY
    )
  endif()
  set(GIT_COMMAND git submodule update --recursive --rebase "${TARGET_FOLDER}")
endif()

set(RETRY_I 1)
while(${RETRY_I} LESS_EQUAL ${RETRY_COUNT})
  set(COMMAND_ERROR_IS_FATAL)
  if(${RETRY_I} EQUAL ${RETRY_COUNT})
    set(IS_FATAL COMMAND_ERROR_IS_FATAL ANY)
  endif()
  execute_process(
    COMMAND ${GIT_COMMAND}
    WORKING_DIRECTORY "${SOURCE_DESTINATION}"
    RESULT_VARIABLE GIT_SUBMODULE_FAILED
    ${IS_FATAL}
  )
  if(${GIT_SUBMODULE_FAILED} EQUAL 0)
    break()
  endif()
  math(EXPR RETRY_I "${RETRY_I} + 1")
  message("git submodule operation failed, try ${RETRY_I} out of ${RETRY_COUNT}")
  execute_process(COMMAND "${CMAKE_COMMAND}" -E sleep ${RETRY_WAIT})
endwhile()

execute_process(
  COMMAND git checkout ${GIT_TAG}
  WORKING_DIRECTORY "${SOURCE_DESTINATION}/${TARGET_FOLDER}"
  COMMAND_ERROR_IS_FATAL ANY
)

set(RETRY_I 1)
while(${RETRY_I} LESS_EQUAL ${RETRY_COUNT})
  set(COMMAND_ERROR_IS_FATAL)
  if(${RETRY_I} EQUAL ${RETRY_COUNT})
    set(IS_FATAL COMMAND_ERROR_IS_FATAL ANY)
  endif()
  execute_process(
    COMMAND git submodule update --init --recursive
    WORKING_DIRECTORY "${SOURCE_DESTINATION}/${TARGET_FOLDER}"
    RESULT_VARIABLE GIT_SUBMODULE_FAILED
    ${IS_FATAL}
  )
  if(${GIT_SUBMODULE_FAILED} EQUAL 0)
    break()
  endif()
  math(EXPR RETRY_I "${RETRY_I} + 1")
  message("git submodule operation failed, try ${RETRY_I} out of ${RETRY_COUNT}")
  execute_process(COMMAND "${CMAKE_COMMAND}" -E sleep ${RETRY_WAIT})
endwhile()
