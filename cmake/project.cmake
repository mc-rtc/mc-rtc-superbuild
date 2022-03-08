include(cmake/options.cmake)
include(cmake/ros.cmake)
include(cmake/setup-env.cmake)
include(cmake/sources.cmake)
include(cmake/sudo.cmake)

include(CMakeDependentOption)
include(ExternalProject)

add_custom_target(uninstall)

# Wrapper around the ExternalProject_Add function to allow simplified usage
#
# Options
# =======
#
# - CLONE_ONLY Always act as if the CLONE_ONLY option was on
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
  if(TARGET ${NAME})
    return()
  endif()
  get_property(MC_RTC_SUPERBUILD_SOURCES GLOBAL PROPERTY MC_RTC_SUPERBUILD_SOURCES)
  set(options NO_NINJA NO_SOURCE_MONITOR CLONE_ONLY SKIP_TEST SKIP_SYMBOLIC_LINKS)
  set(oneValueArgs ${MC_RTC_SUPERBUILD_SOURCES} GIT_TAG SOURCE_DIR BINARY_DIR SUBFOLDER SOURCE_SUBDIR WORKSPACE)
  set(multiValueArgs CMAKE_ARGS BUILD_COMMAND CONFIGURE_COMMAND INSTALL_COMMAND DEPENDS)
  cmake_parse_arguments(ADD_PROJECT_ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
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
  set(CMAKE_ARGS)
  if(ADD_PROJECT_ARGS_CMAKE_ARGS)
    set(CMAKE_ARGS "${ADD_PROJECT_ARGS_CMAKE_ARGS}")
  endif()
  list(PREPEND CMAKE_ARGS
    "-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}"
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
  if(DEFINED CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    list(PREPEND CMAKE_ARGS "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}")
  endif()
  if(ADD_PROJECT_ARGS_SKIP_TEST)
    list(PREPEND CMAKE_ARGS "-DBUILD_TESTING:BOOL=OFF")
  else()
    list(PREPEND CMAKE_ARGS "-DBUILD_TESTING:BOOL=${BUILD_TESTING}")
  endif()
  if(ADD_PROJECT_ARGS_SOURCE_DIR)
    set(SOURCE_DIR "${ADD_PROJECT_ARGS_SOURCE_DIR}")
  else()
    if(ADD_PROJECT_ARGS_SUBFOLDER)
      set(SOURCE_DIR "${SOURCE_DESTINATION}/${ADD_PROJECT_ARGS_SUBFOLDER}/${NAME}")
    else()
      set(SOURCE_DIR "${SOURCE_DESTINATION}/${NAME}")
    endif()
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
    set(CONFIGURE_COMMAND ${COMMAND_PREFIX} ${EMCMAKE} ${CMAKE_COMMAND} -G "${GENERATOR}" -B "${BINARY_DIR}" -S "${SOURCE_DIR}/${ADD_PROJECT_ARGS_SOURCE_SUBDIR}" ${CMAKE_EXTRA_ARGS} ${CMAKE_ARGS})
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
  if(USE_SUDO AND NOT "${INSTALL_COMMAND}" STREQUAL "")
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
  if(NOT ADD_PROJECT_ARGS_SKIP_TEST AND BUILD_TESTING)
    set(TEST_STEP_OPTIONS TEST_AFTER_INSTALL TRUE TEST_COMMAND ${COMMAND_PREFIX} ctest -C $<CONFIG>)
  endif()
  # -- Depends option
  list(APPEND ADD_PROJECT_ARGS_DEPENDS ${GLOBAL_DEPENDS})
  if("${ADD_PROJECT_ARGS_DEPENDS}" STREQUAL "")
    set(DEPENDS "")
  else()
    set(DEPENDS DEPENDS ${ADD_PROJECT_ARGS_DEPENDS})
  endif()
  # -- CLONE_ONLY option
  if(CLONE_ONLY OR ADD_PROJECT_ARGS_CLONE_ONLY)
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
    set(GIT_OPTIONS GIT_REPOSITORY ${GIT_REPOSITORY} GIT_TAG ${GIT_TAG})
  else()
    set(GIT_OPTIONS "")
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
  SetCatkinDependencies(${NAME} "${ADD_PROJECT_ARGS_DEPENDS}" "${ADD_PROJECT_ARGS_WORKSPACE}")
  if(NOT ADD_PROJECT_ARGS_CLONE_ONLY AND NOT ADD_PROJECT_ARGS_WORKSPACE)
    add_custom_target(uninstall-${NAME}
      COMMAND ${CMAKE_COMMAND}
                -DBINARY_DIR=${BINARY_DIR}
                -DUSE_SUDO=${USE_SUDO}
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
  if(NOT "${GIT_REPOSITORY}" STREQUAL "" AND NOT ADD_PROJECT_ARGS_NO_SOURCE_MONITOR)
    # This glob expression forces CMake to re-run if the source directory content changes
    file(GLOB_RECURSE ${NAME}_SOURCES CONFIGURE_DEPENDS "${SOURCE_DIR}/*")
    # But we don't care about all the files
    execute_process(COMMAND git ls-files --recurse-submodules
                    WORKING_DIRECTORY "${SOURCE_DIR}"
                    OUTPUT_VARIABLE ${NAME}_SOURCES
                    ERROR_QUIET
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
    string(REPLACE "\n" ";" ${NAME}_SOURCES "${${NAME}_SOURCES}")
    list(TRANSFORM ${NAME}_SOURCES PREPEND "${SOURCE_DIR}/")
    ExternalProject_Add_Step(${NAME} check-sources
      DEPENDEES patch
      DEPENDERS configure
      DEPENDS ${${NAME}_SOURCES}
    )
    # This makes sure the output of git ls-files is usable
    ExternalProject_Add_Step(${NAME} set-git-config
      COMMAND  git config core.quotepath off
      WORKING_DIRECTORY <SOURCE_DIR>
      DEPENDEES download
      DEPENDERS update
      INDEPENDENT ON
    )
  endif()
  if(NOT "${GIT_REPOSITORY}" STREQUAL "" AND GIT_TAG MATCHES "^origin/(.*)")
    set(LOCAL_BRANCH "${CMAKE_MATCH_1}")
    string(REPLACE "/" "_" LOCAL_BRANCH_ "${LOCAL_BRANCH}")
    ExternalProject_Add_Step(${NAME} checkout-${LOCAL_BRANCH_}
      COMMAND git checkout ${LOCAL_BRANCH}
      WORKING_DIRECTORY <SOURCE_DIR>
      DEPENDEES download
      DEPENDERS update
      INDEPENDENT ON
    )
  endif()
  if(NOT CLONE_ONLY AND NOT ADD_PROJECT_ARGS_SKIP_SYMBOLIC_LINKS)
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
  set(oneValueArgs SUBFOLDER)
  set(multiValueArgs)
  if(NOT TARGET ${PROJECT})
    message(FATAL_ERROR "Cannot add a plugin to unknown project: ${PROJECT}")
  endif()
  cmake_parse_arguments(ADD_PROJECT_PLUGIN_ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
  ExternalProject_Get_Property(${PROJECT} SOURCE_DIR)
  set(PLUGIN_DEST_DIR  "${SOURCE_DIR}/${ADD_PROJECT_PLUGIN_ARGS_SUBFOLDER}/${NAME}")
  AddProject(${NAME}
    SOURCE_DIR "${PLUGIN_DEST_DIR}"
    BINARY_DIR "${PLUGIN_DEST_DIR}"
    CLONE_ONLY
    ${ADD_PROJECT_PLUGIN_ARGS_UNPARSED_ARGUMENTS}
  )
  if(NOT TARGET ${PROJECT}-configure)
    ExternalProject_Add_StepTargets(${PROJECT} configure)
  endif()
  add_dependencies(${PROJECT}-configure ${NAME})
endfunction()
