include(cmake/options.cmake)
include(cmake/ros.cmake)
include(cmake/setup-env.cmake)
include(cmake/sudo.cmake)

include(CMakeDependentOption)
include(ExternalProject)

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
# - GIT_USE_SSH Use SSH for cloning/updating git repository for GITHUB/GITE repos
# - GITHUB <org/project> Use https://github.com/org/project as GIT_REPOSITORY
# - GITE <org/project> Use https://gite.lirmm.fr/org/project as GIT_REPOSITORY
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
  set(options NO_NINJA NO_SOURCE_MONITOR CLONE_ONLY GIT_USE_SSH SKIP_TEST SKIP_SYMBOLIC_LINKS)
  set(oneValueArgs GITHUB GITE GIT_REPOSITORY GIT_TAG SOURCE_DIR BINARY_DIR SUBFOLDER SOURCE_SUBDIR WORKSPACE)
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
  # Handle GITHUB
  if(ADD_PROJECT_ARGS_GITHUB)
    set(GIT_REPOSITORY "${ADD_PROJECT_ARGS_GITHUB}")
    if(ADD_PROJECT_ARGS_GIT_USE_SSH)
      set(GIT_REPOSITORY "git@github.com:${GIT_REPOSITORY}")
    else()
      set(GIT_REPOSITORY "https://github.com/${GIT_REPOSITORY}")
    endif()
  endif()
  # Handle GITE
  if(ADD_PROJECT_ARGS_GITE)
    if(DEFINED GIT_REPOSITORY)
      message(FATAL_ERROR "Only one of GITHUB/GITE/GIT_REPOSITORY must be provided")
    endif()
    set(GIT_REPOSITORY "${ADD_PROJECT_ARGS_GITE}")
    if(ADD_PROJECT_ARGS_GIT_USE_SSH)
      set(GIT_REPOSITORY "git@gite.lirmm.fr:${GIT_REPOSITORY}")
    else()
      set(GIT_REPOSITORY "https://gite.lirmm.fr/${GIT_REPOSITORY}")
    endif()
  endif()
  # Handle GIT_REPOSITORY
  if(ADD_PROJECT_ARGS_GIT_REPOSITORY)
    if(DEFINED GIT_REPOSITORY)
      message(FATAL_ERROR "Only one of GITHUB/GITE/GIT_REPOSITORY must be provided")
    endif()
    set(GIT_REPOSITORY "${ADD_PROJECT_ARGS_GIT_REPOSITORY}")
  endif()
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
    list(PREPEND CMAKE_ARGS
      "-DBUILD_TESTING:BOOL=OFF"
    )
  endif()
  cmake_dependent_option(UPDATE_${NAME} "Update ${NAME}" ON "UPDATE_ALL" OFF)
  if(UPDATE_${NAME})
    set(UPDATE_DISCONNECTED OFF)
  else()
    set(UPDATE_DISCONNECTED ON)
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
  get_command_prefix(COMMAND_PREFIX)
  # -- Configure command
  if(NOT ADD_PROJECT_ARGS_CONFIGURE_COMMAND AND NOT CONFIGURE_COMMAND IN_LIST ADD_PROJECT_ARGS_KEYWORDS_MISSING_VALUES)
    set(CONFIGURE_COMMAND ${COMMAND_PREFIX} ${CMAKE_COMMAND} -G "${GENERATOR}" -B "${BINARY_DIR}" -S "${SOURCE_DIR}/${ADD_PROJECT_ARGS_SOURCE_SUBDIR}" ${CMAKE_ARGS})
  else()
    if("${ADD_PROJECT_ARGS_CONFIGURE_COMMAND}" STREQUAL "")
      set(CONFIGURE_COMMAND ${CMAKE_COMMAND} -E true)
    else()
      set(CONFIGURE_COMMAND ${COMMAND_PREFIX} ${ADD_PROJECT_ARGS_CONFIGURE_COMMAND})
    endif()
  endif()
  # -- Build command
  if(NOT ADD_PROJECT_ARGS_BUILD_COMMAND AND NOT BUILD_COMMAND IN_LIST ADD_PROJECT_ARGS_KEYWORDS_MISSING_VALUES)
    set(BUILD_COMMAND ${COMMAND_PREFIX} ${CMAKE_COMMAND} --build . --config $<CONFIG>)
  else()
    if("${ADD_PROJECT_ARGS_BUILD_COMMAND}" STREQUAL "")
      set(BUILD_COMMAND ${CMAKE_COMMAND} -E true)
    else()
      set(BUILD_COMMAND ${COMMAND_PREFIX} ${ADD_PROJECT_ARGS_BUILD_COMMAND})
    endif()
  endif()
  # -- Install command
  if(NOT ADD_PROJECT_ARGS_INSTALL_COMMAND AND NOT INSTALL_COMMAND IN_LIST ADD_PROJECT_ARGS_KEYWORDS_MISSING_VALUES)
    set(INSTALL_COMMAND  ${CMAKE_COMMAND} --build ${BINARY_DIR} --target install --config $<CONFIG>)
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
  if(NOT ADD_PROJECT_ARGS_SKIP_TEST)
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
    message("UPDATE_DISCONNECTED: ${UPDATE_DISCONNECTED}")
    message("CONFIGURE_COMMAND IS: ${CONFIGURE_COMMAND}")
    message("BUILD_COMMAND IS: ${BUILD_COMMAND}")
    message("INSTALL_COMMAND IS: ${INSTALL_COMMAND}")
    message("EXTRA_INSTALL_COMMAND IS: ${EXTRA_INSTALL_COMMAND}")
    message("TEST_STEP_OPTIONS: ${TEST_STEP_OPTIONS}")
    message("DEPENDS: ${DEPENDS}")
    message("UNPARSED_ARGUMENTS: ${ADD_PROJECT_ARGS_UNPARSED_ARGUMENTS}")
  endif()
  ExternalProject_Add(${NAME}
    PREFIX "${PROJECT_BINARY_DIR}/prefix/${NAME}"
    SOURCE_DIR ${SOURCE_DIR}
    BINARY_DIR ${BINARY_DIR}
    GIT_REPOSITORY ${GIT_REPOSITORY}
    GIT_TAG ${GIT_TAG}
    UPDATE_DISCONNECTED ${UPDATE_DISCONNECTED}
    CONFIGURE_COMMAND ${CONFIGURE_COMMAND}
    BUILD_COMMAND ${BUILD_COMMAND}
    INSTALL_COMMAND ${INSTALL_COMMAND}
    ${EXTRA_INSTALL_COMMAND}
    USES_TERMINAL_INSTALL TRUE
    ${TEST_STEP_OPTIONS}
    ${DEPENDS}
    ${ADD_PROJECT_ARGS_UNPARSED_ARGUMENTS}
  )
  set_catkin_dependencies(${NAME} "${ADD_PROJECT_ARGS_DEPENDS}" "${ADD_PROJECT_ARGS_WORKSPACE}")
  if(NOT ADD_PROJECT_ARGS_NO_SOURCE_MONITOR)
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
  if(GIT_TAG MATCHES "^origin/(.*)")
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
    ensure_valid_workspace(${WORKSPACE})
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
