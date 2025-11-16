include(cmake/apt.cmake)
include(cmake/download.cmake)
include(cmake/extensions.cmake)
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

add_custom_target(
  self-update
  COMMAND
    ${CMAKE_COMMAND} -DNAME=mc-rtc-superbuild -DSOURCE_DIR=${PROJECT_SOURCE_DIR}
    -DGIT_TAG=origin/main -P ${CMAKE_CURRENT_LIST_DIR}/scripts/update-project.cmake
)

# Wrapper around the ExternalProject_Add function to allow simplified usage
#
# Options
# =======
#
# * CLONE_ONLY Only clone the repository
# * SKIP_TEST Do not run tests
# * SKIP_SYMBOLIC_LINKS Skip symbolic links creation mandated by LINK_BUILD_AND_SRC and
#   LINK_COMPILE_COMMANDS
# * NO_SOURCE_MONITOR Do not monitor source for changes
# * NO_NINJA Indicate that the project is not compatible with the Ninja generator
# * PARALLEL_JOBS <num> number of parallel jobs to use when building this (0 lets Ninja decice, make will build on a single core)
# * NO_COLOR Disables color output for projects that do not support it
# * SUBFOLDER <folder> sub-folder of SOURCE_DESTINATION where to clone the project (also
#   used as a sub-folder of BUILD_DESTINATION)
# * APT_PACKAGES provide a list of packages to be installed instead of building from
#   source when USE_MC_RTC_APT_MIRROR=ON
# * APT_DEPENDENCIES external apt dependencies to be installed (from all available
#   system-wide package repositories)
#
# Variables
# =========
#
# * GLOBAL_DEPENDS those projects are added to every project dependencies
#
# Override variables
# =================
# The following global variables may be used to override default project configuration.
# These are meant to be used by script (CI, etc) to install projects with a specific
# configuration (correct branch/remote, etc).
#
# * MC_RTC_SUPERBUILD_OVERRIDE_<NAME>_<SOURCE> overrides the SOURCE property
# * MC_RTC_SUPERBUILD_OVERRIDE_<NAME>_GIT_TAG overrides the GIT_TAG property

function(AddProject NAME)
  get_property(MC_RTC_SUPERBUILD_SOURCES GLOBAL PROPERTY MC_RTC_SUPERBUILD_SOURCES)
  set(options NO_NINJA NO_COLOR NO_SOURCE_MONITOR CLONE_ONLY SKIP_TEST
              SKIP_SYMBOLIC_LINKS
  )
  set(oneValueArgs
      ${MC_RTC_SUPERBUILD_SOURCES}
      GIT_TAG
      SOURCE_DIR
      BINARY_DIR
      SUBFOLDER
      WORKSPACE
      LINK_TO
      SOURCE_SUBDIR
      INSTALL_PREFIX
      PARALLEL_JOBS
  )
  set(multiValueArgs
      CMAKE_ARGS
      BUILD_COMMAND
      CONFIGURE_COMMAND
      INSTALL_COMMAND
      DEPENDS
      APT_PACKAGES
      APT_DEPENDENCIES
  )
  cmake_parse_arguments(
    ADD_PROJECT_ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN}
  )
  list(APPEND ADD_PROJECT_ARGS_DEPENDS ${GLOBAL_DEPENDS})

  # Handle --parallel jobs option
  # Ensure variables are defined and numeric
  if(NOT DEFINED BUILD_PARALLEL_JOBS)
    set(BUILD_PARALLEL_JOBS 0)
  endif()
  if(NOT DEFINED ADD_PROJECT_ARGS_PARALLEL_JOBS OR "${ADD_PROJECT_ARGS_PARALLEL_JOBS}"
                                                   STREQUAL ""
  )
    set(ADD_PROJECT_ARGS_PARALLEL_JOBS 0)
  endif()

  # Compute number of parallel jobs to use
  # If per-project option is set it is used only if it is lower than the global option
  set(EFFECTIVE_PARALLEL_JOBS 0)
  if(BUILD_PARALLEL_JOBS GREATER 0 AND ADD_PROJECT_ARGS_PARALLEL_JOBS GREATER 0)
    math(
      EXPR
      EFFECTIVE_PARALLEL_JOBS
      "(${BUILD_PARALLEL_JOBS} < ${ADD_PROJECT_ARGS_PARALLEL_JOBS}) ? ${BUILD_PARALLEL_JOBS} : ${ADD_PROJECT_ARGS_PARALLEL_JOBS}"
    )
  elseif(BUILD_PARALLEL_JOBS GREATER 0)
    set(EFFECTIVE_PARALLEL_JOBS "${BUILD_PARALLEL_JOBS}")
  elseif(ADD_PROJECT_ARGS_PARALLEL_JOBS GREATER 0)
    set(EFFECTIVE_PARALLEL_JOBS "${ADD_PROJECT_ARGS_PARALLEL_JOBS}")
  endif()

  set(PARALLEL_OPT "")
  if(EFFECTIVE_PARALLEL_JOBS GREATER 0)
    set(PARALLEL_OPT "--parallel ${EFFECTIVE_PARALLEL_JOBS}")
  endif()

  # Handle external dependencies
  # XXX: we should provide a way to install some tool
  # packages from mc_rtc apt repository (such as mesh_sampling) without having to
  # install mc_rtc itself from packages
  if(NOT USE_MC_RTC_APT_MIRROR AND ADD_PROJECT_ARGS_APT_DEPENDENCIES)
    set(APT_DEPENDENCIES)
    foreach(PKG ${ADD_PROJECT_ARGS_APT_DEPENDENCIES})
      list(APPEND APT_DEPENDENCIES ${PKG})
    endforeach()
    AptInstall(${APT_DEPENDENCIES})
  endif()

  if(USE_MC_RTC_APT_MIRROR AND ADD_PROJECT_ARGS_APT_PACKAGES)
    set(APT_PACKAGES)
    foreach(PKG ${ADD_PROJECT_ARGS_APT_PACKAGES})
      string(REGEX MATCH "^ros-" IS_ROS_PKG "${PKG}")
      if(IS_ROS_PKG AND NOT WITH_ROS_SUPPORT)
        continue()
      endif()
      string(REGEX MATCH "^python-" IS_PYTHON2_PKG "${PKG}")
      if(IS_PYTHON2_PKG AND NOT APT_HAS_PYTHON2_PACKAGES)
        continue()
      endif()
      list(APPEND APT_PACKAGES ${PKG})
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
      # Override the SOURCE if set
      if(MC_RTC_SUPERBUILD_OVERRIDE_${NAME}_${SOURCE})
        set(GIT_REPOSITORY
            "${GIT_REPOSITORY}${MC_RTC_SUPERBUILD_OVERRIDE_${NAME}_${SOURCE}}"
        )
        message(
          WARNING
            "Overriding ${SOURCE} property for project ${NAME} because MC_RTC_SUPERBUILD_OVERRIDE_${NAME}_${SOURCE} is set:
Previous      : ${SOURCE} \"${ADD_PROJECT_ARGS_${SOURCE}}\"
Using         : ${SOURCE} \"${MC_RTC_SUPERBUILD_OVERRIDE_${NAME}_${SOURCE}}\"
Git repository: \"${GIT_REPOSITORY}\""
        )
      else()
        set(GIT_REPOSITORY "${GIT_REPOSITORY}${ADD_PROJECT_ARGS_${SOURCE}}")
      endif()
    endif()
  endforeach()
  # Handle GIT_TAG
  if(MC_RTC_SUPERBUILD_OVERRIDE_${NAME}_GIT_TAG)
    set(GIT_TAG "${MC_RTC_SUPERBUILD_OVERRIDE_${NAME}_GIT_TAG}")
    message(
      WARNING
        "Overriding GIT_TAG property for project ${NAME} because MC_RTC_SUPERBUILD_OVERRIDE_${NAME}_GIT_TAG is set:
Previous: GIT_TAG \"${ADD_PROJECT_ARGS_GIT_TAG}\"
Using   : GIT_TAG \"${GIT_TAG}\""
    )
  elseif(ADD_PROJECT_ARGS_GIT_TAG)
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
  cmake_path(
    RELATIVE_PATH SOURCE_DIR BASE_DIRECTORY "${SOURCE_DESTINATION}" OUTPUT_VARIABLE
    RELATIVE_SOURCE_DIR
  )
  set(STAMP_DIR "${PROJECT_BINARY_DIR}/prefix/${NAME}/src/${NAME}-stamp/")
  # Handle multiple definition of the same project This could happen if the same project
  # is included in multiple extensions for example We check if the same remote/branch
  # has been defined and error out if not
  if(TARGET ${NAME})
    set(PREVIOUS_GIT_REPOSITORY "${MC_RTC_SUPERBUILD_${NAME}_GIT_REPOSITORY}")
    set(PREVIOUS_GIT_TAG "${MC_RTC_SUPERBUILD_${NAME}_GIT_TAG}")
    if("${PREVIOUS_GIT_REPOSITORY}" STREQUAL "${GIT_REPOSITORY}"
       AND "${PREVIOUS_GIT_TAG}" STREQUAL "${GIT_TAG}"
    )
      return()
    endif()
    message(
      FATAL_ERROR
        "${NAME} was already defined in ${MC_RTC_SUPERBUILD_${NAME}_DEFINITION_SOURCE} with a different source.
This is trying to use:
  ${GIT_REPOSITORY}#${GIT_TAG}
But the previous call used:
  ${PREVIOUS_GIT_REPOSITORY}#${PREVIOUS_GIT_TAG}
This is likely a conflict between different extensions."
    )
  endif()
  if(MC_RTC_SUPERBUILD_PRE_COMMIT)
    set(PRE_COMMIT_OPTION -DPRE_COMMIT=${MC_RTC_SUPERBUILD_PRE_COMMIT})
  else()
    set(PRE_COMMIT_OPTION)
  endif()
  if(NOT "${GIT_REPOSITORY}" STREQUAL "")
    add_custom_command(
      OUTPUT "${STAMP_DIR}/${NAME}-submodule-init"
      COMMAND
        "${CMAKE_COMMAND}" -DSOURCE_DESTINATION=${SOURCE_DESTINATION}
        -DTARGET_FOLDER=${RELATIVE_SOURCE_DIR} -DGIT_REPOSITORY=${GIT_REPOSITORY}
        -DGIT_TAG=${GIT_TAG} -DLINK_TO=${LINK_TO} -DOPERATION="init"
        -DSTAMP_OUT=${STAMP_DIR}/${NAME}-submodule-init ${PRE_COMMIT_OPTION} -P
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/scripts/git-submodule-init-update.cmake
      COMMENT "Init ${NAME} repository"
    )
    add_custom_target(
      ${NAME}-submodule-init DEPENDS "${STAMP_DIR}/${NAME}-submodule-init"
    )
  else()
    add_custom_target(${NAME}-submodule-init)
  endif()
  add_dependencies(${NAME}-submodule-init init-superbuild)
  foreach(DEP ${ADD_PROJECT_ARGS_DEPENDS})
    if(TARGET ${DEP}-submodule-update)
      add_dependencies(${NAME}-submodule-init ${DEP}-submodule-update)
    endif()
  endforeach()
  # This is true if the project was added in a previous run If the repository has
  # already been cloned the operation might lose local work if it hasn't been saved,
  # therefore we check for this and error if there is local changes
  if(DEFINED MC_RTC_SUPERBUILD_${NAME}_GIT_REPOSITORY)
    message(
      CONFIGURE_LOG
      "MC_RTC_SUPERBUILD_${NAME}_GIT_REPOSITORY is defined: ${MC_RTC_SUPERBUILD_${NAME}_GIT_REPOSITORY}"
    )

    # GIT_REPOSITORY and/or GIT_TAG have changed
    if(EXISTS "${SOURCE_DIR}/.git")
      message(CONFIGURE_LOG "${SOURCE_DIR}/.git exists")
      message(CONFIGURE_LOG "working dir is ${SOURCE_DIR}")
      # Get current repository origin remote url
      execute_process(
        COMMAND git config --local --get remote.origin.url
        WORKING_DIRECTORY "${SOURCE_DIR}"
        OUTPUT_VARIABLE PREVIOUS_GIT_REPOSITORY
        OUTPUT_STRIP_TRAILING_WHITESPACE
      )

      # Get current branch
      execute_process(
        COMMAND git symbolic-ref --short HEAD
        WORKING_DIRECTORY "${SOURCE_DIR}"
        OUTPUT_VARIABLE PREVIOUS_GIT_REF
        OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET
      )

      # if the branch does not exist, check if it is a tag
      if(PREVIOUS_GIT_REF STREQUAL "")
        execute_process(
          COMMAND git describe --tags --exact-match HEAD
          WORKING_DIRECTORY "${SOURCE_DIR}"
          OUTPUT_VARIABLE PREVIOUS_GIT_TAG
          OUTPUT_STRIP_TRAILING_WHITESPACE
        )
      else()
        set(PREVIOUS_GIT_TAG origin/${PREVIOUS_GIT_REF})
      endif()

      message(CONFIGURE_LOG
              "Previous repository is ${PREVIOUS_GIT_REPOSITORY}#${PREVIOUS_GIT_TAG}"
      )
    else()
      message(CONFIGURE_LOG "${SOURCE_DIR}/.git does not exist")
      set(PREVIOUS_GIT_REPOSITORY "${MC_RTC_SUPERBUILD_${NAME}_GIT_REPOSITORY}")
      set(PREVIOUS_GIT_TAG "${MC_RTC_SUPERBUILD_${NAME}_GIT_TAG}")
      message(CONFIGURE_LOG
              "Previous repository is ${PREVIOUS_GIT_REPOSITORY}#${PREVIOUS_GIT_TAG}"
      )
    endif()

    if(NOT "${PREVIOUS_GIT_REPOSITORY}" STREQUAL "${GIT_REPOSITORY}"
       OR NOT "${PREVIOUS_GIT_TAG}" STREQUAL "${GIT_TAG}"
    )
      # GIT_REPOSITORY and/or GIT_TAG have changed
      if(EXISTS "${SOURCE_DIR}/.git")
        set(GIT_COMMIT_EXTRA_MSG
            "Updating from ${PREVIOUS_GIT_REPOSITORY}#${PREVIOUS_GIT_TAG} to ${GIT_REPOSITORY}#${GIT_TAG}"
        )
        message(
          "-- ${NAME} repository will be updated from ${PREVIOUS_GIT_REPOSITORY}#${PREVIOUS_GIT_TAG} to ${GIT_REPOSITORY}#${GIT_TAG}"
        )
        # Update local remote and branch if there is no unpushed local changes
        # Error out otherwise
        add_custom_command(
          OUTPUT "${STAMP_DIR}/${NAME}-submodule-update"
          COMMAND
            "${CMAKE_COMMAND}" -DSOURCE_DESTINATION=${SOURCE_DESTINATION}
            -DTARGET_FOLDER=${RELATIVE_SOURCE_DIR} -DGIT_REPOSITORY=${GIT_REPOSITORY}
            -DGIT_TAG=${GIT_TAG} -DLINK_TO=${LINK_TO}
            -DSTAMP_OUT=${STAMP_DIR}/${NAME}-submodule-update -DOPERATION="update"
            -DGIT_COMMIT_EXTRA_MSG=${GIT_COMMIT_EXTRA_MSG} -P
            ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/scripts/git-submodule-init-update.cmake
          COMMENT "Update ${NAME} repository settings"
        )
        add_custom_target(
          ${NAME}-submodule-update DEPENDS "${STAMP_DIR}/${NAME}-submodule-update"
        )
      endif()
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
  list(
    PREPEND
    CMAKE_ARGS
    "-DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}"
    "-DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=ON"
    "-DINSTALL_DOCUMENTATION:BOOL=${INSTALL_DOCUMENTATION}"
    "-DPYTHON_BINDING:BOOL=${PYTHON_BINDING}"
    "-DNANOBIND_BINDINGS:BOOL=${NANOBIND_BINDINGS}"
    "-DPYTHON_BINDING_USER_INSTALL:BOOL=${PYTHON_BINDING_USER_INSTALL}"
    "-DPYTHON_BINDING_FORCE_PYTHON2:BOOL=${PYTHON_BINDING_FORCE_PYTHON2}"
    "-DPYTHON_BINDING_FORCE_PYTHON3:BOOL=${PYTHON_BINDING_FORCE_PYTHON3}"
    "-DPYTHON_BINDING_BUILD_PYTHON2_AND_PYTHON3:BOOL=${PYTHON_BINDING_BUILD_PYTHON2_AND_PYTHON3}"
  )

  handle_compiler_launcher(CMAKE_ARGS)

  if(WIN32)
    list(PREPEND CMAKE_ARGS "-DBOOST_ROOT=${BOOST_ROOT}")
  endif()
  if(APPLE)
    list(PREPEND CMAKE_ARGS "-DCMAKE_MACOSX_RPATH:BOOL=ON"
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
  GetCommandPrefix(COMMAND_PREFIX "${STAMP_DIR}/cmake-prefix.cmake")
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
  if(NOT ADD_PROJECT_ARGS_CONFIGURE_COMMAND
     AND NOT CONFIGURE_COMMAND IN_LIST ADD_PROJECT_ARGS_KEYWORDS_MISSING_VALUES
  )
    if(ADD_PROJECT_ARGS_SOURCE_SUBDIR)
      set(CONFIGURE_SOURCE_DIR ${SOURCE_DIR}/${ADD_PROJECT_ARGS_SOURCE_SUBDIR})
    else()
      set(CONFIGURE_SOURCE_DIR ${SOURCE_DIR})
    endif()
    set(CONFIGURE_COMMAND
        ${COMMAND_PREFIX} ${EMCMAKE} ${CMAKE_COMMAND} -G "${GENERATOR}" -B
        "${BINARY_DIR}" -S "${CONFIGURE_SOURCE_DIR}" ${CMAKE_EXTRA_ARGS} ${CMAKE_ARGS}
    )
  else()
    if("${ADD_PROJECT_ARGS_CONFIGURE_COMMAND}" STREQUAL "")
      set(CONFIGURE_COMMAND ${CMAKE_COMMAND} -E true)
    else()
      set(CONFIGURE_COMMAND ${COMMAND_PREFIX} ${ADD_PROJECT_ARGS_CONFIGURE_COMMAND})
    endif()
  endif()
  # -- Build command
  if(NOT ADD_PROJECT_ARGS_BUILD_COMMAND AND NOT BUILD_COMMAND IN_LIST
                                            ADD_PROJECT_ARGS_KEYWORDS_MISSING_VALUES
  )
    set(BUILD_COMMAND ${COMMAND_PREFIX} ${EMMAKE} ${CMAKE_COMMAND} --build
                      ${BINARY_DIR} ${PARALLEL_OPT} --config $<CONFIG>
    )
  else()
    if("${ADD_PROJECT_ARGS_BUILD_COMMAND}" STREQUAL "")
      set(BUILD_COMMAND ${CMAKE_COMMAND} -E true)
    else()
      set(BUILD_COMMAND ${COMMAND_PREFIX} ${ADD_PROJECT_ARGS_BUILD_COMMAND})
    endif()
  endif()
  # -- Install command
  if(NOT ADD_PROJECT_ARGS_INSTALL_COMMAND AND NOT INSTALL_COMMAND IN_LIST
                                              ADD_PROJECT_ARGS_KEYWORDS_MISSING_VALUES
  )
    set(INSTALL_COMMAND
        ${COMMAND_PREFIX} ${EMMAKE} ${CMAKE_COMMAND} --build ${BINARY_DIR}
        ${PARALLEL_OPT} --target install --config $<CONFIG>
    )
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
      execute_process(
        COMMAND whoami
        OUTPUT_VARIABLE USER
        OUTPUT_STRIP_TRAILING_WHITESPACE
      )
    else()
      set(USER $ENV{USER})
    endif()
    if(NOT ADD_PROJECT_ARGS_NO_NINJA)
      set(EXTRA_INSTALL_COMMAND
          COMMAND /bin/bash -c
          "${SUDO_CMD} chown -f ${USER} ${BINARY_DIR}/.ninja_deps ${BINARY_DIR}/.ninja_log || true"
      )
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
    set(TEST_STEP_OPTIONS
        TEST_AFTER_INSTALL
        TRUE
        TEST_COMMAND
        ${COMMAND_PREFIX}
        ctest
        -C
        $<CONFIG>
        ${VERBOSE_OPTION}
        --rerun-failed
        --output-on-failure
    )
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
    set(TEST_STEP_OPTIONS
        TEST_AFTER_INSTALL
        FALSE
        TEST_BEFORE_INSTALL
        FALSE
        TEST_COMMAND
        ${CMAKE_COMMAND}
        -E
        true
    )
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
  ExternalProject_Add(
    ${NAME}
    PREFIX "${PROJECT_BINARY_DIR}/prefix/${NAME}"
    SOURCE_DIR ${SOURCE_DIR}
    BINARY_DIR ${BINARY_DIR}
    ${GIT_OPTIONS}
    UPDATE_DISCONNECTED ON # We handle updates ourselves with an explicit target
    CONFIGURE_COMMAND ${CONFIGURE_COMMAND}
    BUILD_COMMAND ${BUILD_COMMAND}
    INSTALL_COMMAND ${INSTALL_COMMAND} ${EXTRA_INSTALL_COMMAND}
    USES_TERMINAL_INSTALL TRUE
    ${TEST_STEP_OPTIONS} ${DEPENDS} ${ADD_PROJECT_ARGS_UNPARSED_ARGUMENTS}
  )
  add_custom_target(
    force-${NAME}
    COMMAND "${CMAKE_COMMAND}" -E remove "${STAMP_DIR}/${NAME}-configure"
    COMMAND "${CMAKE_COMMAND}" --build "${PROJECT_BINARY_DIR}" ${PARALLEL_OPT} --target
            ${NAME} --config $<CONFIG>
  )
  if(SOURCE_DIR_DID_NOT_EXIST)
    file(REMOVE "${SOURCE_DIR}/.mc-rtc-superbuild")
    execute_process(
      COMMAND
        ${CMAKE_COMMAND} -DSOURCE_DIR=${SOURCE_DIR}
        -DSOURCE_DESTINATION=${SOURCE_DESTINATION} -P
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/scripts/clean-src-folders.cmake"
    )
  endif()
  ExternalProject_Add_StepTargets(${NAME} configure)
  add_dependencies(${NAME} ${NAME}-submodule-update)
  add_dependencies(${NAME}-configure ${NAME}-submodule-update)
  SetCatkinDependencies(
    ${NAME} "${ADD_PROJECT_ARGS_DEPENDS}" "${ADD_PROJECT_ARGS_WORKSPACE}"
  )
  if(NOT ADD_PROJECT_ARGS_CLONE_ONLY AND NOT ADD_PROJECT_ARGS_WORKSPACE)
    add_custom_target(
      uninstall-${NAME}
      COMMAND
        ${CMAKE_COMMAND} -DBINARY_DIR=${BINARY_DIR}
        -DUSE_SUDO=${INSTALL_PREFIX_USE_SUDO} -DSUDO_CMD=${SUDO_CMD}
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
  add_custom_target(
    update-${NAME}
    COMMAND
      ${CMAKE_COMMAND} -DNAME=${NAME} -DSOURCE_DIR=${SOURCE_DIR} -DGIT_TAG=${GIT_TAG}
      -DSOURCE_DESTINATION=${SOURCE_DESTINATION} -DTARGET_FOLDER=${RELATIVE_SOURCE_DIR}
      -DLINK_TO=${LINK_TO} ${PRE_COMMIT_OPTION} -P
      ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/scripts/update-project.cmake
  )
  add_dependencies(update update-${NAME})
  if(NOT "${GIT_REPOSITORY}" STREQUAL "" AND NOT ADD_PROJECT_ARGS_NO_SOURCE_MONITOR)
    SetupSourceMonitor(${NAME} "${SOURCE_DIR}")
    # This makes sure the output of git ls-files is usable
    ExternalProject_Add_Step(
      ${NAME} set-git-config
      COMMAND git config core.quotepath off
      WORKING_DIRECTORY <SOURCE_DIR>
      DEPENDEES download
      DEPENDERS update INDEPENDENT ON
    )
  endif()
  if(NOT WIN32)
    if(NOT ADD_PROJECT_ARGS_SKIP_SYMBOLIC_LINKS)
      if(LINK_BUILD_AND_SRC)
        ExternalProject_Add_Step(
          ${NAME} link-build-and-src
          COMMAND
            ${CMAKE_COMMAND} -DSOURCE_DIR=${SOURCE_DIR} -DBINARY_DIR=${BINARY_DIR}
            -DBUILD_LINK_SUFFIX=${BUILD_LINK_SUFFIX} -P
            ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/scripts/link-source-and-build.cmake
          DEPENDEES configure
          DEPENDS ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/scripts/link-source-and-build.cmake
        )
      endif()
      if(LINK_COMPILE_COMMANDS)
        ExternalProject_Add_Step(
          ${NAME} link-compile-commands
          COMMAND
            ${CMAKE_COMMAND} -DSOURCE_DIR=${SOURCE_DIR} -DBINARY_DIR=${BINARY_DIR} -P
            ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/scripts/link-compile-commands.cmake
          DEPENDEES configure
          DEPENDS ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/scripts/link-compile-commands.cmake
        )
      endif()
    endif()
  endif()
  # Save some of the project properties in the cache so we can: - Check that multiple
  # projects are added with the same properties or error out - Warn the user about
  # unsaved data if the scripts change branch
  set(MC_RTC_SUPERBUILD_${NAME}_GIT_REPOSITORY
      "${GIT_REPOSITORY}"
      CACHE INTERNAL ""
  )
  set(MC_RTC_SUPERBUILD_${NAME}_GIT_TAG
      "${GIT_TAG}"
      CACHE INTERNAL ""
  )
  set(MC_RTC_SUPERBUILD_${NAME}_DEFINITION_SOURCE
      "${CMAKE_CURRENT_LIST_DIR}"
      CACHE INTERNAL ""
  )
endfunction()

# Wrapper around AddProject
#
# Options
# =======
#
# * WORKSPACE Catkin workspace where the project is cloned, this option is required
function(AddCatkinProject NAME)
  set(options INSTALL_DEPENDENCIES)
  set(oneValueArgs WORKSPACE)
  set(multiValueArgs)
  cmake_parse_arguments(
    ADD_CATKIN_PROJECT_ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN}
  )
  if(NOT ADD_CATKIN_PROJECT_ARGS_WORKSPACE)
    message(FATAL_ERROR "WORKSPACE must be provided when calling AddCatkinProject")
  endif()
  set(WORKSPACE "${ADD_CATKIN_PROJECT_ARGS_WORKSPACE}")
  if(WITH_ROS_SUPPORT)
    ensurevalidcatkinworkspace(${WORKSPACE})
    get_property(WORKSPACE_DIR GLOBAL PROPERTY CATKIN_WORKSPACE_${WORKSPACE}_DIR)
    get_property(WORKSPACE_STAMP GLOBAL PROPERTY CATKIN_WORKSPACE_${WORKSPACE}_STAMP)
    AddProject(
      ${NAME}
      SOURCE_DIR "${WORKSPACE_DIR}/src/${NAME}" BINARY_DIR
      "${WORKSPACE_DIR}/src/${NAME}"
      CONFIGURE_COMMAND ${CMAKE_COMMAND} -E rm -f "${WORKSPACE_STAMP}"
      BUILD_COMMAND ""
      INSTALL_COMMAND "" WORKSPACE ${WORKSPACE}
      SKIP_TEST SKIP_SYMBOLIC_LINKS ${ADD_CATKIN_PROJECT_ARGS_UNPARSED_ARGUMENTS}
    )
    add_dependencies(catkin-build-${WORKSPACE} ${NAME})
    set_property(GLOBAL APPEND PROPERTY CATKIN_WORKSPACE_${WORKSPACE} "${NAME}")

    if(ADD_CATKIN_PROJECT_ARGS_INSTALL_DEPENDENCIES)
      ExternalProject_Add_Step(
        ${NAME} install_dependencies
        COMMAND ${SUDO_CMD} rosdep update && rosdep install --from-path src --ignore-src
                -y
        WORKING_DIRECTORY ${WORKSPACE_DIR}
        DEPENDEES download
        DEPENDERS configure
      )
    endif()
  else()
    AddProject(${NAME} ${ADD_CATKIN_PROJECT_ARGS_UNPARSED_ARGUMENTS})
  endif()
endfunction()

# Add a plugin to an existing project
#
# Options
# =======
#
# * SUBFOLDER Directory inside the main project where the plugin should be cloned
function(AddProjectPlugin NAME PROJECT)
  set(options)
  set(oneValueArgs SUBFOLDER LINK_NAME)
  set(multiValueArgs)
  if(NOT TARGET ${PROJECT})
    message(FATAL_ERROR "Cannot add a plugin to unknown project: ${PROJECT}")
  endif()
  cmake_parse_arguments(
    ADD_PROJECT_PLUGIN_ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN}
  )
  ExternalProject_Get_Property(${PROJECT} SOURCE_DIR)
  set(PLUGIN_DEST_DIR
      "${SOURCE_DESTINATION}/.plugins/${PROJECT}_${ADD_PROJECT_PLUGIN_ARGS_SUBFOLDER}_${NAME}"
  )
  set(LINK_TO "${SOURCE_DIR}/${ADD_PROJECT_PLUGIN_ARGS_SUBFOLDER}")
  if(ADD_PROJECT_PLUGIN_ARGS_LINK_NAME)
    set(LINK_TO "${LINK_TO}/${ADD_PROJECT_PLUGIN_ARGS_LINK_NAME}")
  else()
    set(LINK_TO "${LINK_TO}/${NAME}")
  endif()
  AddProject(
    ${NAME}
    SOURCE_DIR
    "${PLUGIN_DEST_DIR}"
    BINARY_DIR
    "${PLUGIN_DEST_DIR}"
    LINK_TO
    "${LINK_TO}"
    CLONE_ONLY
    ${ADD_PROJECT_PLUGIN_ARGS_UNPARSED_ARGUMENTS}
  )
  add_dependencies(${PROJECT}-configure ${NAME})
endfunction()
