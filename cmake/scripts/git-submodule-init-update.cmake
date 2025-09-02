# How many times we retry before giving up
set(RETRY_COUNT 5)
# How much time (seconds) we wait between attempts
set(RETRY_WAIT 15)

if(GIT_TAG MATCHES "^origin/(.*)")
  set(GIT_TAG_IS_TAG OFF)
  string(REGEX REPLACE "^origin/" "" GIT_TAG "${GIT_TAG}")
else()
  set(GIT_TAG_IS_TAG ON)
endif()

if("${OPERATION}" STREQUAL "init")
  if(EXISTS "${SOURCE_DESTINATION}/${TARGET_FOLDER}/.git")
    execute_process(COMMAND ${CMAKE_COMMAND} -E touch ${STAMP_OUT})
    return()
  endif()
  if(EXISTS "${SOURCE_DESTINATION}/${TARGET_FOLDER}")
    file(REMOVE_RECURSE "${SOURCE_DESTINATION}/${TARGET_FOLDER}")
  endif()
  set(BRANCH_OPTION -b ${GIT_TAG})
  if(GIT_TAG_IS_TAG)
    set(BRANCH_OPTION)
  endif()
  message(
    STATUS
      "Adding submodule '${TARGET_FOLDER}' from '${GIT_REPOSITORY}' at tag/branch '${GIT_TAG}'"
  )
  execute_process(
    COMMAND git submodule add -f ${BRANCH_OPTION} ${GIT_REPOSITORY} "${TARGET_FOLDER}"
    WORKING_DIRECTORY "${SOURCE_DESTINATION}"
    RESULT_VARIABLE GIT_SUBMODULE_FAILED
  )
  if(NOT GIT_SUBMODULE_FAILED EQUAL 0)
    message(
      FATAL_ERROR "Failed to add submodule '${TARGET_FOLDER}' from '${GIT_REPOSITORY}'."
    )
  endif()
elseif("${OPERATION}" STREQUAL "update")
  # The "update" operation attemps to change to the new branch/tag specified for this project. It does its best to ensure that the local branch is in a clean state before switching to the new branch/tag and that no data is lost in the process.

  # Do git remote update
  execute_process(
    COMMAND git remote update origin
    WORKING_DIRECTORY "${SOURCE_DESTINATION}/${TARGET_FOLDER}"
    RESULT_VARIABLE GIT_SUBMODULE_FAILED
    OUTPUT_QUIET
  )

  # Check for uncommitted changes
  execute_process(
    COMMAND git status --porcelain
    WORKING_DIRECTORY "${SOURCE_DESTINATION}/${TARGET_FOLDER}"
    OUTPUT_VARIABLE GIT_STATUS_OUTPUT
    RESULT_VARIABLE GIT_STATUS_RESULT
  )
  if(NOT "${GIT_STATUS_OUTPUT}" STREQUAL "")
    message(
      FATAL_ERROR
        "Local branch '${GIT_TAG}' in '${SOURCE_DESTINATION}/${TARGET_FOLDER}' has uncommitted local changes. Please commit or stash them before updating."
    )
  endif()

  # Try to get current branch name
  execute_process(
    COMMAND git symbolic-ref --short -q HEAD
    WORKING_DIRECTORY "${SOURCE_DESTINATION}/${TARGET_FOLDER}"
    OUTPUT_VARIABLE GIT_CURRENT_REF
    OUTPUT_STRIP_TRAILING_WHITESPACE OUTPUT_QUIET
  )

  # If we are on a local branch, check that it has been fully pushed to the remote
  if(GIT_CURRENT_REF)
    # Check if upstream is set for the current branch
    execute_process(
      COMMAND git rev-parse --abbrev-ref --symbolic-full-name @{u}
      WORKING_DIRECTORY "${SOURCE_DESTINATION}/${TARGET_FOLDER}"
      RESULT_VARIABLE GIT_UPSTREAM_RESULT
      OUTPUT_VARIABLE GIT_UPSTREAM_BRANCH
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(NOT GIT_UPSTREAM_RESULT EQUAL 0)
      message(
        FATAL_ERROR
          "No upstream (remote tracking branch) is set for the current branch ${GIT_CURRENT_TAG} in '${SOURCE_DESTINATION}/${TARGET_FOLDER}'.\n"
          "Set it with:\n"
          "  git branch --set-upstream-to=<remote>/${GIT_CURRENT_TAG} ${GIT_CURRENT_TAG}\n"
          "Or push the branch with:\n"
          "  git push -u <remote> ${GIT_CURRENT_TAG}"
      )
    endif()

    # Check if local branch is fully pushed
    execute_process(
      COMMAND git rev-list --count @{u}..
      WORKING_DIRECTORY "${SOURCE_DESTINATION}/${TARGET_FOLDER}"
      OUTPUT_VARIABLE AHEAD_COUNT
      OUTPUT_STRIP_TRAILING_WHITESPACE
      RESULT_VARIABLE GIT_REV_RESULT
    )
    if(GIT_REV_RESULT)
      message(FATAL_ERROR "Failed to check if branch is pushed. Is the upstream set?")
    endif()
    if(NOT AHEAD_COUNT STREQUAL "0")
      message(
        FATAL_ERROR
          "Local branch has commits not pushed to remote. Please push before updating."
      )
    endif()
  endif()

  if(GIT_TAG_IS_TAG)
    # checkout new tag
    execute_process(
      COMMAND git checkout "${GIT_TAG}"
      WORKING_DIRECTORY "${SOURCE_DESTINATION}/${TARGET_FOLDER}"
      RESULT_VARIABLE CHECKOUT_RESULT
    )
  else() # we are updating from a branch on the remote
    # Check if there is a local branch with the same name as the new branch
    execute_process(
      COMMAND git branch --list "${GIT_TAG}"
      WORKING_DIRECTORY "${SOURCE_DESTINATION}/${TARGET_FOLDER}"
      OUTPUT_VARIABLE BRANCH_EXISTS
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    # Get URI of previous remote
    execute_process(
      COMMAND git remote get-url origin
      WORKING_DIRECTORY "${SOURCE_DESTINATION}/${TARGET_FOLDER}"
      OUTPUT_VARIABLE PREVIOUS_REMOTE
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    # Set URI or origin remote to GIT_REPOSITORY
    execute_process(
      COMMAND git remote set-url origin "${GIT_REPOSITORY}"
      COMMAND git remote update origin
      WORKING_DIRECTORY "${SOURCE_DESTINATION}/${TARGET_FOLDER}"
      RESULT_VARIABLE SET_URL_RESULT
    )
    if(NOT SET_URL_RESULT EQUAL 0)
      # Restore PREVIOUS_REMOTE
      execute_process(
        COMMAND git remote set-url origin "${PREVIOUS_REMOTE}"
        COMMAND git remote update origin
        WORKING_DIRECTORY "${SOURCE_DESTINATION}/${TARGET_FOLDER}"
        RESULT_VARIABLE SET_URL_RESULT
      )
      message(FATAL_ERROR "Failed to set remote URL to '${GIT_REPOSITORY}'.")
    endif()

    # Ensure that the branch exists on the remote
    execute_process(
      COMMAND git ls-remote --heads origin ${GIT_TAG}
      WORKING_DIRECTORY "${SOURCE_DESTINATION}/${TARGET_FOLDER}"
      OUTPUT_VARIABLE BRANCH_EXISTS_OUTPUT
      RESULT_VARIABLE GIT_LS_REMOTE_RESULT
    )

    if(BRANCH_EXISTS_OUTPUT)
      message(STATUS "Branch '${GIT_TAG}' exists on remote '${GIT_REPOSITORY}'.")
    else()
      # Restore PREVIOUS_REMOTE
      execute_process(
        COMMAND git remote set-url origin "${PREVIOUS_REMOTE}"
        COMMAND git remote update origin
        WORKING_DIRECTORY "${SOURCE_DESTINATION}/${TARGET_FOLDER}"
        RESULT_VARIABLE SET_URL_RESULT
      )
      message(
        FATAL_ERROR
          "Branch '${GIT_TAG}' does NOT exist on remote '${GIT_REPOSITORY}'. If you meant to create it, use\n  cd ${SOURCE_DESTINATION}/${TARGET_FOLDER}\n  git checkout -b ${GIT_TAG}\n  git push --set-upstream origin ${GIT_TAG}\n"
      )
    endif()

    # Checkout the new branch from remote
    if(BRANCH_EXISTS)
      message(
        STATUS
          "Branch '${GIT_TAG}' already exists locally. Resetting its HEAD to the remote's new HEAD."
      )
      # Ensure that we are on this branch locally
      execute_process(
        COMMAND git checkout "${GIT_TAG}"
        WORKING_DIRECTORY "${SOURCE_DESTINATION}/${TARGET_FOLDER}"
        RESULT_VARIABLE CHECKOUT_RESULT
      )
      if(NOT CHECKOUT_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to checkout branch '${GIT_TAG}'.")
      endif()

      # Check if local branch is ahead of remote
      execute_process(
        COMMAND git rev-list --count origin/${GIT_TAG}..${GIT_TAG}
        WORKING_DIRECTORY "${SOURCE_DESTINATION}/${TARGET_FOLDER}"
        OUTPUT_VARIABLE LOCAL_AHEAD_COUNT
        OUTPUT_STRIP_TRAILING_WHITESPACE
      )

      if(NOT LOCAL_AHEAD_COUNT STREQUAL "0")
        message(
          FATAL_ERROR
            "Local branch '${GIT_TAG}' in '${SOURCE_DESTINATION}/${TARGET_FOLDER}' has commits not pushed to remote. Please push or backup your changes before updating."
        )
      endif()

      # Reset that branch to some other branch/commit, e.g. target-branch
      execute_process(
        COMMAND git reset --hard "origin/${GIT_TAG}"
        WORKING_DIRECTORY "${SOURCE_DESTINATION}/${TARGET_FOLDER}"
        RESULT_VARIABLE CHECKOUT_RESULT
      )
      if(NOT CHECKOUT_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to reset branch '${GIT_TAG}'.")
      endif()
    else()
      message(
        STATUS
          "Branch '${GIT_TAG}' does not exist locally. Checking it out from remote ${GIT_REPOSITORY}."
      )
      execute_process(
        COMMAND git checkout -b "${GIT_TAG}" "origin/${GIT_TAG}"
        WORKING_DIRECTORY "${SOURCE_DESTINATION}/${TARGET_FOLDER}"
        RESULT_VARIABLE CHECKOUT_RESULT
      )
      if(NOT CHECKOUT_RESULT EQUAL 0)
        message(
          FATAL_ERROR
            "Failed to checkout branch '${GIT_TAG}' from remote ${GIT_REPOSITORY}."
        )
      endif()
    endif()
  endif()

  # We are now on the correct branch/remote
  # Update the superbuild workspace submodule
  function(update_gitmodules PARENT_REPO_PATH SUBMODULE_PATH SUBMODULE_URL
           SUBMODULE_BRANCH
  )
    set(GITMODULES_FILE "${PARENT_REPO_PATH}/.gitmodules")

    # Read existing .gitmodules content
    file(READ "${GITMODULES_FILE}" GITMODULES_CONTENT)

    # Prepare new entry
    set(NEW_ENTRY
        "[submodule \"${SUBMODULE_PATH}\"]\n    path = ${SUBMODULE_PATH}\n    url = ${SUBMODULE_URL}\n    branch = ${SUBMODULE_BRANCH}\n"
    )

    # Remove existing entry for the submodule path (simple regex)
    string(REGEX REPLACE "\\[submodule \"${SUBMODULE_PATH}\"\\][^\[]*" ""
                         GITMODULES_CONTENT "${GITMODULES_CONTENT}"
    )

    # Append new entry
    set(GITMODULES_CONTENT "${GITMODULES_CONTENT}${NEW_ENTRY}")

    # Write back to .gitmodules
    file(WRITE "${GITMODULES_FILE}" "${GITMODULES_CONTENT}")
  endfunction()

  update_gitmodules(
    ${SOURCE_DESTINATION} ${TARGET_FOLDER} "${GIT_REPOSITORY}" "${GIT_TAG}"
  )
endif() # end update

if(NOT "${LINK_TO}" STREQUAL "")
  if(NOT WIN32)
    file(CREATE_LINK "${SOURCE_DESTINATION}/${TARGET_FOLDER}" "${LINK_TO}" SYMBOLIC)
  else()
    file(COPY "${SOURCE_DESTINATION}/${TARGET_FOLDER}" "${LINK_TO}")
    if("${OPERATION}" STREQUAL "init")
      file(APPEND "${SOURCE_DESTINATION}/.gitignore" "${LINK_TO}/*")
    endif()
  endif()
endif()

# Update project's submodules
set(RETRY_I 1)
while(${RETRY_I} LESS_EQUAL ${RETRY_COUNT})
  set(COMMAND_ERROR_IS_FATAL)
  if(${RETRY_I} EQUAL ${RETRY_COUNT})
    set(IS_FATAL COMMAND_ERROR_IS_FATAL ANY)
  endif()
  execute_process(
    COMMAND git submodule update --init --recursive
    WORKING_DIRECTORY "${SOURCE_DESTINATION}/${TARGET_FOLDER}"
    RESULT_VARIABLE GIT_SUBMODULE_FAILED ${IS_FATAL}
  )
  if(${GIT_SUBMODULE_FAILED} EQUAL 0)
    break()
  endif()
  math(EXPR RETRY_I "${RETRY_I} + 1")
  execute_process(COMMAND "${CMAKE_COMMAND}" -E sleep ${RETRY_WAIT})
  message("git submodule operation failed, try ${RETRY_I} out of ${RETRY_COUNT}")
endwhile()

if(NOT "${LINK_TO}" STREQUAL "")
  cmake_path(
    RELATIVE_PATH LINK_TO BASE_DIRECTORY "${SOURCE_DESTINATION}" OUTPUT_VARIABLE
    RELATIVE_LINK
  )
  set(COMMIT_EXTRA_MSG "\n\nCloned to ${TARGET_FOLDER}")
  set(COMMIT_MSG "[${RELATIVE_LINK}] ")
else()
  set(COMMIT_EXTRA_MSG "")
  set(COMMIT_MSG "[${TARGET_FOLDER}] ")
endif()
if("${OPERATION}" STREQUAL "init")
  set(COMMIT_MSG "${COMMIT_MSG}Added submodule\n\nUsing ${GIT_REPOSITORY}#${GIT_TAG}")
else()
  set(COMMIT_MSG "${COMMIT_MSG}Updated submodule\n\n${GIT_COMMIT_EXTRA_MSG}")
endif()
set(COMMIT_MSG "${COMMIT_MSG}${COMMIT_EXTRA_MSG}")
message(WARNING "commit_msg: ${COMMIT_MSG}")

message(
  STATUS "Committing changes to submodule '${TARGET_FOLDER}' in '${SOURCE_DESTINATION}'"
)
execute_process(
  COMMAND git add -f "${TARGET_FOLDER}" .gitmodules
  WORKING_DIRECTORY "${SOURCE_DESTINATION}"
  OUTPUT_QUIET
)
execute_process(
  COMMAND git commit -m "${COMMIT_MSG}"
  WORKING_DIRECTORY "${SOURCE_DESTINATION}"
  OUTPUT_QUIET
)

if(DEFINED PRE_COMMIT
   AND EXISTS "${SOURCE_DIR}/.pre-commit-config.yaml"
   AND EXISTS "${SOURCE_DIR}/.git"
)
  execute_process(
    COMMAND ${PRE_COMMIT} install
    WORKING_DIRECTORY ${SOURCE_DIR}
    OUTPUT_QUIET ERROR_QUIET COMMAND_ERROR_IS_FATAL ANY
  )
endif()

execute_process(COMMAND ${CMAKE_COMMAND} -E touch ${STAMP_OUT})
