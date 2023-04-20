include(cmake/apt.cmake)
include(cmake/download.cmake)
include(cmake/options.cmake)
include(cmake/ros.cmake)
include(cmake/setup-env.cmake)
include(cmake/setup-source-monitor.cmake)
include(cmake/sources.cmake)
include(cmake/sudo.cmake)

include(CMakeDependentOption)
include(ExternalProject)

add_custom_target(clone)
add_custom_target(uninstall)
add_custom_target(update)

# Wrapper around the ExternalProject_Add function to allow simplified usage
#
# Options
# =======
#
# - CLONE_ONLY Only clone the repository
# - SKIP_TEST Do not run tests
# - SKIP_SYMBOLIC_LINKS Skip symbolic links creation mandated by LINK_BUILD_AND_SRC and LINK_COMPILE_COMMANDS
# - NO_SOURCE_MONITOR Do not monitor source for changes
# - NO_NINJA Indicate that the project is not compatible with the Ninja generator
# - SUBFOLDER <folder> sub-folder of SOURCE_DESTINATION where to clone the project (also used as a sub-folder of BUILD_DESTINATION)
#
# Variables
# =========
#
# - GLOBAL_DEPENDS those projects are added to every project dependencies
#

function(AddProject NAME)
  get_property(MC_RTC_SUPERBUILD_SOURCES GLOBAL PROPERTY MC_RTC_SUPERBUILD_SOURCES)
  set(options NO_NINJA NO_SOURCE_MONITOR CLONE_ONLY SKIP_TEST SKIP_SYMBOLIC_LINKS)
  set(oneValueArgs ${MC_RTC_SUPERBUILD_SOURCES} GIT_TAG SOURCE_DIR BINARY_DIR SUBFOLDER WORKSPACE LINK_TO SOURCE_SUBDIR INSTALL_PREFIX)
  set(multiValueArgs CMAKE_ARGS BUILD_COMMAND CONFIGURE_COMMAND INSTALL_COMMAND DEPENDS APT_PACKAGES)
  cmake_parse_arguments(ADD_PROJECT_ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
  list(APPEND ADD_PROJECT_ARGS_DEPENDS ${GLOBAL_DEPENDS})
  if(USE_MC_RTC_APT_MIRROR AND ADD_PROJECT_ARGS_APT_PACKAGES)
    set(APT_PACKAGES)
    foreach(PKG ${ADD_PROJECT_ARGS_APT_PACKAGES})
      string(SUBSTRING "${PKG}" 0 4 PKG_START)
      if("${PKG_START}" STREQUAL "ros-")
        if(WITH_ROS_SUPPORT)
          list(APPEND APT_PACKAGES ${PKG})
        endif()
      else()
        list(APPEND APT_PACKAGES ${PKG})
      endif()
    endforeach()
    AptInstall(${APT_PACKAGES})
    add_custom_target(${NAME})
    foreach(DEP ${ADD_PROJECT_ARGS_DEPENDS})
      add_dependencies(${NAME} ${DEP})
    endforeach()
    return()
  endif()
  # Handle GIT_REPOSITORY
  set(GIT_REPOSITORY "")
  foreach(SOURCE ${MC_RTC_SUPERBUILD_SOURCES})
    if(ADD_PROJECT_ARGS_${SOURCE})
      if(NOT "${GIT_REPOSITORY}" STREQUAL "")
        message(FATAL_ERROR "Multiple sources have been specified for ${NAME}")
      endif()
      get_property(GIT_REPOSITORY GLOBAL PROPERTY MC_RTC_SUPERBUILD_SOURCES_${SOURCE})
      set(GIT_REPOSITORY "${GIT_REPOSITORY}${ADD_PROJECT_ARGS_${SOURCE}}")
    endif()
  endforeach()
  # Handle GIT_TAG
  if(ADD_PROJECT_ARGS_GIT_TAG)
    set(GIT_TAG "${ADD_PROJECT_ARGS_GIT_TAG}")
  else()
    set(GIT_TAG "origin/main")
  endif()
  # Handle SOURCE_DIR
  if(ADD_PROJECT_ARGS_SOURCE_DIR)
    set(SOURCE_DIR "${ADD_PROJECT_ARGS_SOURCE_DIR}")
  else()
    if(ADD_PROJECT_ARGS_SUBFOLDER)
      set(SOURCE_DIR "${SOURCE_DESTINATION}/${ADD_PROJECT_ARGS_SUBFOLDER}/${NAME}")
    else()
      set(SOURCE_DIR "${SOURCE_DESTINATION}/${NAME}")
    endif()
  endif()
  # Handle SUBMODULE_NAME
  if(ADD_PROJECT_ARGS_LINK_TO)
    set(LINK_TO "${ADD_PROJECT_ARGS_LINK_TO}")
  else()
    set(LINK_TO "")
  endif()
  cmake_path(RELATIVE_PATH SOURCE_DIR BASE_DIRECTORY "${SOURCE_DESTINATION}" OUTPUT_VARIABLE RELATIVE_SOURCE_DIR)
  set(STAMP_DIR "${PROJECT_BINARY_DIR}/prefix/${NAME}/src/${NAME}-stamp/")
  # Handle multiple definition of the same project
  # This could happen if the same project is included in multiple extensions for example
  # We check if the same remote/branch has been defined and error out if not
  if(TARGET ${NAME})
    set(PREVIOUS_GIT_REPOSITORY "${MC_RTC_SUPERBUILD_${NAME}_GIT_REPOSITORY}")
    set(PREVIOUS_GIT_TAG "${MC_RTC_SUPERBUILD_${NAME}_GIT_TAG}")
    if("${PREVIOUS_GIT_REPOSITORY}" STREQUAL "${GIT_REPOSITORY}" AND
        "${PREVIOUS_GIT_TAG}" STREQUAL "${GIT_TAG}")
      return()
    endif()
    message(FATAL_ERROR "${NAME} was already defined in ${MC_RTC_SUPERBUILD_${NAME}_DEFINITION_SOURCE} with a different source.
This is trying to use:
  ${GIT_REPOSITORY}#${GIT_TAG}
But the previous call used:
  ${PREVIOUS_GIT_REPOSITORY}#${PREVIOUS_GIT_TAG}
This is likely a conflict between different extensions.")
  endif()
  if(NOT "${GIT_REPOSITORY}" STREQUAL "")
    add_custom_command(
      OUTPUT "${STAMP_DIR}/${NAME}-submodule-init"
      COMMAND
        "${CMAKE_COMMAND}"
          -DSOURCE_DESTINATION=${SOURCE_DESTINATION}
          -DTARGET_FOLDER=${RELATIVE_SOURCE_DIR}
          -DGIT_REPOSITORY=${GIT_REPOSITORY}
          -DGIT_TAG=${GIT_TAG}
          -DLINK_TO=${LINK_TO}
          -DOPERATION="init"
          -DSTAMP_OUT=${STAMP_DIR}/${NAME}-submodule-init
          -P ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/scripts/git-submodule-init-update.cmake
      COMMENT "Init ${NAME} repository"
    )
    add_custom_target(${NAME}-submodule-init DEPENDS "${STAMP_DIR}/${NAME}-submodule-init")
  else()
    add_custom_target(${NAME}-submodule-init)
  endif()
  add_dependencies(${NAME}-submodule-init init-superbuild)
  foreach(DEP ${ADD_PROJECT_ARGS_DEPENDS})
    if(TARGET ${DEP}-submodule-update)
      add_dependencies(${NAME}-submodule-init ${DEP}-submodule-update)
    endif()
  endforeach()
  # This is true if the project was added in a previous run
  # If the repository has already been cloned the operation might lose local work if it hasn't been saved,
  # therefore we check for this and error if there is local changes
  if(DEFINED MC_RTC_SUPERBUILD_${NAME}_GIT_REPOSITORY)
    set(PREVIOUS_GIT_REPOSITORY "${MC_RTC_SUPERBUILD_${NAME}_GIT_REPOSITORY}")
    set(PREVIOUS_GIT_TAG "${MC_RTC_SUPERBUILD_${NAME}_GIT_TAG}")
    if(NOT "${PREVIOUS_GIT_REPOSITORY}" STREQUAL "${GIT_REPOSITORY}" OR
        NOT "${PREVIOUS_GIT_TAG}" STREQUAL "${GIT_TAG}")
      # GIT_REPOSITORY and/or GIT_TAG have changed, we check if there was any local changes
      if(EXISTS "${SOURCE_DIR}/.git")
        execute_process(COMMAND git diff-index --quiet ${PREVIOUS_GIT_TAG} --
          WORKING_DIRECTORY "${SOURCE_DIR}"
          RESULT_VARIABLE GIT_HAS_ANY_CHANGES)
        if(GIT_HAS_ANY_CHANGES)
          message(FATAL_ERROR "The repository for ${NAME} changed.
From
  ${PREVIOUS_GIT_REPOSITORY}#${PREVIOUS_GIT_TAG}
To
  ${GIT_REPOSITORY}#${GIT_TAG}

You have local changes in ${SOURCE_DIR} that would be overwritten by this change. Save your work before continuing")
        endif()
      endif()
      set(GIT_COMMIT_EXTRA_MSG "Updating from ${PREVIOUS_GIT_REPOSITORY}#${PREVIOUS_GIT_TAG} to ${GIT_REPOSITORY}#${GIT_TAG}")
      message("-- ${NAME} repository will be updated from ${PREVIOUS_GIT_REPOSITORY}#${PREVIOUS_GIT_TAG} to ${GIT_REPOSITORY}#${GIT_TAG}")
      add_custom_command(
        OUTPUT "${STAMP_DIR}/${NAME}-submodule-update"
        COMMAND
          "${CMAKE_COMMAND}"
            -DSOURCE_DESTINATION=${SOURCE_DESTINATION}
            -DTARGET_FOLDER=${RELATIVE_SOURCE_DIR}
            -DGIT_REPOSITORY=${GIT_REPOSITORY}
            -DGIT_TAG=${GIT_TAG}
            -DLINK_TO=${LINK_TO}
            -DSTAMP_OUT=${STAMP_DIR}/${NAME}-submodule-update
            -DOPERATION="update"
            -DGIT_COMMIT_EXTRA_MSG=${GIT_COMMIT_EXTRA_MSG}
            -P ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/scripts/git-submodule-init-update.cmake
        COMMENT "Update ${NAME} repository settings"
      )
      add_custom_target(${NAME}-submodule-update DEPENDS "${STAMP_DIR}/${NAME}-submodule-update")
    endif()
  endif()
  if(NOT TARGET ${NAME}-submodule-update)
    add_custom_target(${NAME}-submodule-update)
  endif()
  add_dependencies(${NAME}-submodule-update ${NAME}-submodule-init)
  add_custom_target(clone-${NAME})
  add_dependencies(clone-${NAME} ${NAME}-submodule-update)
  add_dependencies(clone clone-${NAME})
  # Handle NO_NINJA
  if(NOT WIN32)
    if(ADD_PROJECT_ARGS_NO_NINJA)
      set(GENERATOR "Unix Makefiles")
    else()
      set(GENERATOR "Ninja")
    endif()
  else()
    set(GENERATOR "${CMAKE_GENERATOR}")
  endif()
  set(CMAKE_ARGS)
  if(ADD_PROJECT_ARGS_CMAKE_ARGS)
    set(CMAKE_ARGS "${ADD_PROJECT_ARGS_CMAKE_ARGS}")
  endif()
  if(ADD_PROJECT_ARGS_INSTALL_PREFIX)
    set(INSTALL_PREFIX ${ADD_PROJECT_ARGS_INSTALL_PREFIX})
    PrefixRequireSudo(${INSTALL_PREFIX} INSTALL_PREFIX_USE_SUDO)
  else()
    set(INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX})
    set(INSTALL_PREFIX_USE_SUDO ${USE_SUDO})
  endif()
  list(PREPEND CMAKE_ARGS
    "-DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}"
    "-DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=ON"
    "-DINSTALL_DOCUMENTATION:BOOL=${INSTALL_DOCUMENTATION}"
    "-DPYTHON_BINDING:BOOL=${PYTHON_BINDING}"
    "-DPYTHON_BINDING_USER_INSTALL:BOOL=${PYTHON_BINDING_USER_INSTALL}"
    "-DPYTHON_BINDING_FORCE_PYTHON2:BOOL=${PYTHON_BINDING_FORCE_PYTHON2}"
    "-DPYTHON_BINDING_FORCE_PYTHON3:BOOL=${PYTHON_BINDING_FORCE_PYTHON3}"
    "-DPYTHON_BINDING_BUILD_PYTHON2_AND_PYTHON3:BOOL=${PYTHON_BINDING_BUILD_PYTHON2_AND_PYTHON3}"
  )
  if(WIN32)
    list(PREPEND CMAKE_ARGS
      "-DBOOST_ROOT=${BOOST_ROOT}"
    )
  endif()
  if(APPLE)
    list(PREPEND CMAKE_ARGS
      "-DCMAKE_MACOSX_RPATH:BOOL=ON"
      "-DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}"
      "-DCMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES}"
    )
  endif()
  if(DEFINED CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    list(PREPEND CMAKE_ARGS "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}")
  endif()
  if(ADD_PROJECT_ARGS_SKIP_TEST)
    list(PREPEND CMAKE_ARGS "-DBUILD_TESTING:BOOL=OFF")
  else()
    list(PREPEND CMAKE_ARGS "-DBUILD_TESTING:BOOL=${BUILD_TESTING}")
  endif()
  if(ADD_PROJECT_ARGS_BINARY_DIR)
    set(BINARY_DIR "${ADD_PROJECT_ARGS_BINARY_DIR}")
  else()
    if(ADD_PROJECT_ARGS_SUBFOLDER)
      set(BINARY_DIR "${BUILD_DESTINATION}/${ADD_PROJECT_ARGS_SUBFOLDER}/${NAME}")
    else()
      set(BINARY_DIR "${BUILD_DESTINATION}/${NAME}")
    endif()
  endif()
  GetCommandPrefix(COMMAND_PREFIX)
  if(EMSCRIPTEN)
    set(EMCMAKE emcmake)
    set(EMMAKE emmake)
    list(JOIN CMAKE_FIND_ROOT_PATH ";" CMAKE_FIND_ROOT_PATH_AS_ARG)
    set(CMAKE_EXTRA_ARGS "-DCMAKE_FIND_ROOT_PATH=${CMAKE_INSTALL_PREFIX}")
  else()
    set(EMCMAKE)
    set(EMMAKE)
    set(CMAKE_EXTRA_ARGS)
  endif()
  # -- Configure command
  if(NOT ADD_PROJECT_ARGS_CONFIGURE_COMMAND AND NOT CONFIGURE_COMMAND IN_LIST ADD_PROJECT_ARGS_KEYWORDS_MISSING_VALUES)
    if(ADD_PROJECT_ARGS_SOURCE_SUBDIR)
      set(CONFIGURE_SOURCE_DIR ${SOURCE_DIR}/${ADD_PROJECT_ARGS_SOURCE_SUBDIR})
    else()
      set(CONFIGURE_SOURCE_DIR ${SOURCE_DIR})
    endif()
    set(CONFIGURE_COMMAND ${COMMAND_PREFIX} ${EMCMAKE} ${CMAKE_COMMAND} -G "${GENERATOR}" -B "${BINARY_DIR}" -S "${CONFIGURE_SOURCE_DIR}" ${CMAKE_EXTRA_ARGS} ${CMAKE_ARGS})
  else()
    if("${ADD_PROJECT_ARGS_CONFIGURE_COMMAND}" STREQUAL "")
      set(CONFIGURE_COMMAND ${CMAKE_COMMAND} -E true)
    else()
      set(CONFIGURE_COMMAND ${COMMAND_PREFIX} ${ADD_PROJECT_ARGS_CONFIGURE_COMMAND})
    endif()
  endif()
  # -- Build command
  if(NOT ADD_PROJECT_ARGS_BUILD_COMMAND AND NOT BUILD_COMMAND IN_LIST ADD_PROJECT_ARGS_KEYWORDS_MISSING_VALUES)
    set(BUILD_COMMAND ${COMMAND_PREFIX} ${EMMAKE} ${CMAKE_COMMAND} --build . --config $<CONFIG>)
  else()
    if("${ADD_PROJECT_ARGS_BUILD_COMMAND}" STREQUAL "")
      set(BUILD_COMMAND ${CMAKE_COMMAND} -E true)
    else()
      set(BUILD_COMMAND ${COMMAND_PREFIX} ${ADD_PROJECT_ARGS_BUILD_COMMAND})
    endif()
  endif()
  # -- Install command
  if(NOT ADD_PROJECT_ARGS_INSTALL_COMMAND AND NOT INSTALL_COMMAND IN_LIST ADD_PROJECT_ARGS_KEYWORDS_MISSING_VALUES)
    set(INSTALL_COMMAND ${EMMAKE} ${CMAKE_COMMAND} --build ${BINARY_DIR} --target install --config $<CONFIG>)
  else()
    if("${ADD_PROJECT_ARGS_INSTALL_COMMAND}" STREQUAL "")
      set(INSTALL_COMMAND "")
    else()
      set(INSTALL_COMMAND ${COMMAND_PREFIX} ${ADD_PROJECT_ARGS_INSTALL_COMMAND})
    endif()
  endif()
  if(INSTALL_PREFIX_USE_SUDO AND NOT "${INSTALL_COMMAND}" STREQUAL "")
    set(INSTALL_COMMAND ${SUDO_CMD} -E ${INSTALL_COMMAND})
    if(NOT DEFINED ENV{USER})
      execute_process(COMMAND whoami OUTPUT_VARIABLE USER OUTPUT_STRIP_TRAILING_WHITESPACE)
    else()
      set(USER $ENV{USER})
    endif()
    if(NOT ADD_PROJECT_ARGS_NO_NINJA)
      set(EXTRA_INSTALL_COMMAND COMMAND /bin/bash -c "${SUDO_CMD} chown -f ${USER} ${BINARY_DIR}/.ninja_deps ${BINARY_DIR}/.ninja_log || true")
    endif()
  endif()
  if(INSTALL_COMMAND STREQUAL "")
    set(INSTALL_COMMAND ${CMAKE_COMMAND} -E true)
  endif()
  # -- Test command
  if(VERBOSE_TEST_OUTPUT)
    set(VERBOSE_OPTION "--extra-verbose")
  else()
    set(VERBOSE_OPTION "")
  endif()
  if(NOT ADD_PROJECT_ARGS_SKIP_TEST AND BUILD_TESTING)
    set(TEST_STEP_OPTIONS TEST_AFTER_INSTALL TRUE TEST_COMMAND ${COMMAND_PREFIX} ctest -C $<CONFIG> ${VERBOSE_OPTION})
  endif()
  # -- Depends option
  if("${ADD_PROJECT_ARGS_DEPENDS}" STREQUAL "")
    set(DEPENDS "")
  else()
    set(DEPENDS DEPENDS ${ADD_PROJECT_ARGS_DEPENDS})
  endif()
  # -- CLONE_ONLY option
  if(ADD_PROJECT_ARGS_CLONE_ONLY)
    set(CONFIGURE_COMMAND ${CMAKE_COMMAND} -E true)
    set(BUILD_COMMAND ${CMAKE_COMMAND} -E true)
    set(INSTALL_COMMAND ${CMAKE_COMMAND} -E true)
    set(EXTRA_INSTALL_COMMAND "")
    set(TEST_STEP_OPTIONS TEST_AFTER_INSTALL FALSE TEST_BEFORE_INSTALL FALSE TEST_COMMAND ${CMAKE_COMMAND} -E true)
  endif()
  if(MC_RTC_SUPERBUILD_VERBOSE)
    message("=============== ${NAME} ===============")
    message("SOURCE_DIR: ${SOURCE_DIR}")
    message("BINARY_DIR: ${BINARY_DIR}")
    message("GIT_REPOSITORY: ${GIT_REPOSITORY}")
    message("GIT_TAG: ${GIT_TAG}")
    message("CONFIGURE_COMMAND IS: ${CONFIGURE_COMMAND}")
    message("BUILD_COMMAND IS: ${BUILD_COMMAND}")
    message("INSTALL_COMMAND IS: ${INSTALL_COMMAND}")
    message("EXTRA_INSTALL_COMMAND IS: ${EXTRA_INSTALL_COMMAND}")
    message("TEST_STEP_OPTIONS: ${TEST_STEP_OPTIONS}")
    message("DEPENDS: ${DEPENDS}")
    message("UNPARSED_ARGUMENTS: ${ADD_PROJECT_ARGS_UNPARSED_ARGUMENTS}")
  endif()
  if(NOT "${GIT_REPOSITORY}" STREQUAL "")
    set(GIT_OPTIONS DOWNLOAD_COMMAND "")
  else()
    set(GIT_OPTIONS "")
  endif()
  set(SOURCE_DIR_DID_NOT_EXIST FALSE)
  if(NOT EXISTS "${SOURCE_DIR}")
    set(SOURCE_DIR_DID_NOT_EXIST TRUE)
    file(MAKE_DIRECTORY "${SOURCE_DIR}")
    file(TOUCH "${SOURCE_DIR}/.mc-rtc-superbuild")
  endif()
  ExternalProject_Add(${NAME}
    PREFIX "${PROJECT_BINARY_DIR}/prefix/${NAME}"
    SOURCE_DIR ${SOURCE_DIR}
    BINARY_DIR ${BINARY_DIR}
    ${GIT_OPTIONS}
    UPDATE_DISCONNECTED ON # We handle updates ourselves with an explicit target
    CONFIGURE_COMMAND ${CONFIGURE_COMMAND}
    BUILD_COMMAND ${BUILD_COMMAND}
    INSTALL_COMMAND ${INSTALL_COMMAND}
    ${EXTRA_INSTALL_COMMAND}
    USES_TERMINAL_INSTALL TRUE
    ${TEST_STEP_OPTIONS}
    ${DEPENDS}
    ${ADD_PROJECT_ARGS_UNPARSED_ARGUMENTS}
  )
  add_custom_target(force-${NAME}
    COMMAND "${CMAKE_COMMAND}" -E remove "${STAMP_DIR}/${NAME}-configure"
    COMMAND "${CMAKE_COMMAND}" --build "${PROJECT_BINARY_DIR}" --target ${NAME} --config $<CONFIG>
  )
  if(SOURCE_DIR_DID_NOT_EXIST)
    file(REMOVE "${SOURCE_DIR}/.mc-rtc-superbuild")
    execute_process(COMMAND ${CMAKE_COMMAND} -DSOURCE_DIR=${SOURCE_DIR} -DSOURCE_DESTINATION=${SOURCE_DESTINATION} -P "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/scripts/clean-src-folders.cmake")
  endif()
  ExternalProject_Add_StepTargets(${NAME} configure)
  add_dependencies(${NAME} ${NAME}-submodule-update)
  add_dependencies(${NAME}-configure ${NAME}-submodule-update)
  SetCatkinDependencies(${NAME} "${ADD_PROJECT_ARGS_DEPENDS}" "${ADD_PROJECT_ARGS_WORKSPACE}")
  if(NOT ADD_PROJECT_ARGS_CLONE_ONLY AND NOT ADD_PROJECT_ARGS_WORKSPACE)
    add_custom_target(uninstall-${NAME}
      COMMAND ${CMAKE_COMMAND}
                -DBINARY_DIR=${BINARY_DIR}
                -DUSE_SUDO=${INSTALL_PREFIX_USE_SUDO}
                -DSUDO_CMD=${SUDO_CMD}
                -DINSTALL_STAMP="${PROJECT_BINARY_DIR}/prefix/${NAME}/src/${NAME}-stamp/${NAME}-install"
                -P ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/scripts/uninstall-project.cmake
      COMMENT "Uninstall ${NAME}"
    )
    add_dependencies(uninstall uninstall-${NAME})
    foreach(DEP ${ADD_PROJECT_ARGS_DEPENDS})
      if(TARGET uninstall-${DEP})
        add_dependencies(uninstall-${DEP} uninstall-${NAME})
      endif()
    endforeach()
  endif()
  add_custom_target(update-${NAME}
    COMMAND ${CMAKE_COMMAND}
              -DNAME=${NAME}
              -DSOURCE_DIR=${SOURCE_DIR}
              -DGIT_TAG=${GIT_TAG}
              -DSOURCE_DESTINATION=${SOURCE_DESTINATION}
              -DTARGET_FOLDER=${RELATIVE_SOURCE_DIR}
              -DLINK_TO=${LINK_TO}
              -P ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/scripts/update-project.cmake
  )
  add_dependencies(update update-${NAME})
  if(NOT "${GIT_REPOSITORY}" STREQUAL "" AND NOT ADD_PROJECT_ARGS_NO_SOURCE_MONITOR)
    SetupSourceMonitor(${NAME} "${SOURCE_DIR}")
    # This makes sure the output of git ls-files is usable
    ExternalProject_Add_Step(${NAME} set-git-config
      COMMAND  git config core.quotepath off
      WORKING_DIRECTORY <SOURCE_DIR>
      DEPENDEES download
      DEPENDERS update
      INDEPENDENT ON
    )
  endif()
  if(NOT WIN32)
    if(NOT ADD_PROJECT_ARGS_SKIP_SYMBOLIC_LINKS)
      if(LINK_BUILD_AND_SRC)
        ExternalProject_Add_Step(${NAME} link-build-and-src
          COMMAND ${CMAKE_COMMAND} -DSOURCE_DIR=${SOURCE_DIR} -DBINARY_DIR=${BINARY_DIR} -DBUILD_LINK_SUFFIX=${BUILD_LINK_SUFFIX} -P ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/scripts/link-source-and-build.cmake
          DEPENDEES configure
          DEPENDS ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/scripts/link-source-and-build.cmake
        )
      endif()
      if(LINK_COMPILE_COMMANDS)
        ExternalProject_Add_Step(${NAME} link-compile-commands
          COMMAND ${CMAKE_COMMAND} -DSOURCE_DIR=${SOURCE_DIR} -DBINARY_DIR=${BINARY_DIR} -P ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/scripts/link-compile-commands.cmake
          DEPENDEES configure
          DEPENDS ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/scripts/link-compile-commands.cmake
        )
      endif()
    endif()
  endif()
  # Save some of the project properties in the cache so we can:
  # - Check that multiple projects are added with the same properties or error out
  # - Warn the user about unsaved data if the scripts change branch
  set(MC_RTC_SUPERBUILD_${NAME}_GIT_REPOSITORY "${GIT_REPOSITORY}" CACHE INTERNAL "")
  set(MC_RTC_SUPERBUILD_${NAME}_GIT_TAG "${GIT_TAG}" CACHE INTERNAL "")
  set(MC_RTC_SUPERBUILD_${NAME}_DEFINITION_SOURCE "${CMAKE_CURRENT_LIST_DIR}" CACHE INTERNAL "")
endfunction()

# Wrapper around AddProject
#
# Options
# =======
#
# - WORKSPACE Catkin workspace where the project is cloned, this option is required
function(AddCatkinProject NAME)
  set(options)
  set(oneValueArgs WORKSPACE)
  set(multiValueArgs)
  cmake_parse_arguments(ADD_CATKIN_PROJECT_ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
  if(NOT ADD_CATKIN_PROJECT_ARGS_WORKSPACE)
    message(FATAL_ERROR "WORKSPACE must be provided when calling AddCatkinProject")
  endif()
  set(WORKSPACE "${ADD_CATKIN_PROJECT_ARGS_WORKSPACE}")
  if(WITH_ROS_SUPPORT)
    EnsureValidCatkinWorkspace(${WORKSPACE})
    get_property(WORKSPACE_DIR GLOBAL PROPERTY CATKIN_WORKSPACE_${WORKSPACE}_DIR)
    get_property(WORKSPACE_STAMP GLOBAL PROPERTY CATKIN_WORKSPACE_${WORKSPACE}_STAMP)
    AddProject(${NAME}
      SOURCE_DIR "${WORKSPACE_DIR}/src/${NAME}"
      BINARY_DIR "${WORKSPACE_DIR}/src/${NAME}"
      CONFIGURE_COMMAND ${CMAKE_COMMAND} -E rm -f "${WORKSPACE_STAMP}"
      BUILD_COMMAND ""
      INSTALL_COMMAND ""
      WORKSPACE ${WORKSPACE}
      SKIP_TEST
      SKIP_SYMBOLIC_LINKS
      ${ADD_CATKIN_PROJECT_ARGS_UNPARSED_ARGUMENTS}
    )
    add_dependencies(catkin-build-${WORKSPACE} ${NAME})
    set_property(GLOBAL APPEND PROPERTY CATKIN_WORKSPACE_${WORKSPACE} "${NAME}")
  else()
    AddProject(${NAME}
      ${ADD_CATKIN_PROJECT_ARGS_UNPARSED_ARGUMENTS}
    )
  endif()
endfunction()

# Add a plugin to an existing project
#
# Options
# =======
#
# - SUBFOLDER Directory inside the main project where the plugin should be cloned
function(AddProjectPlugin NAME PROJECT)
  set(options)
  set(oneValueArgs SUBFOLDER LINK_NAME)
  set(multiValueArgs)
  if(NOT TARGET ${PROJECT})
    message(FATAL_ERROR "Cannot add a plugin to unknown project: ${PROJECT}")
  endif()
  cmake_parse_arguments(ADD_PROJECT_PLUGIN_ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
  ExternalProject_Get_Property(${PROJECT} SOURCE_DIR)
  set(PLUGIN_DEST_DIR  "${SOURCE_DESTINATION}/.plugins/${PROJECT}_${ADD_PROJECT_PLUGIN_ARGS_SUBFOLDER}_${NAME}")
  set(LINK_TO "${SOURCE_DIR}/${ADD_PROJECT_PLUGIN_ARGS_SUBFOLDER}")
  if(ADD_PROJECT_PLUGIN_ARGS_LINK_NAME)
    set(LINK_TO "${LINK_TO}/${ADD_PROJECT_ARGS_LINK_NAME}")
  else()
    set(LINK_TO "${LINK_TO}/${NAME}")
  endif()
  AddProject(${NAME}
    SOURCE_DIR "${PLUGIN_DEST_DIR}"
    BINARY_DIR "${PLUGIN_DEST_DIR}"
    LINK_TO "${LINK_TO}"
    CLONE_ONLY
    ${ADD_PROJECT_PLUGIN_ARGS_UNPARSED_ARGUMENTS}
  )
  add_dependencies(${PROJECT}-configure ${NAME})
endfunction()
