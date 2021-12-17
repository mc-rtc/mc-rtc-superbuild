# Common options for all package

###########################
# -- General options -- #
###########################
option(BUILD_BENCHMARKS "Build benchmarks" OFF)
option(INSTALL_SYSTEM_DEPENDENCIES "Install system dependencies" ON)
option(WITH_LSSOL "Enable LSSOL support" OFF)
if(UNIX AND NOT APPLE)
  set(WITH_ROS_SUPPORT_DEFAULT ON)
else()
  set(WITH_ROS_SUPPORT_DEFAULT OFF)
endif()
option(WITH_ROS_SUPPORT "Enable ROS support" ${WITH_ROS_SUPPORT_DEFAULT})
option(UPDATE_ALL "Update all packages" ON)
option(INSTALL_DOCUMENTATION "Install documentation of the projects" OFF)
option(CLONE_ONLY "Clone (or update) the packages only" OFF)

#########################
# -- Python bindings -- #
#########################
option(PYTHON_BINDING "Generate Python binding" ON)
if(WIN32)
  set(PYTHON_BINDING_USER_INSTALL_DEFAULT ON)
else()
  set(PYTHON_BINDING_USER_INSTALL_DEFAULT OFF)
endif()
option(PYTHON_BINDING_USER_INSTALL "Install the Python binding in user space" ${PYTHON_BINDING_USER_INSTALL_DEFAULT})
option(PYTHON_BINDING_FORCE_PYTHON2 "Use pip2/python2 instead of pip/python" OFF)
option(PYTHON_BINDING_FORCE_PYTHON3 "Use pip3/python3 instead of pip/python" OFF)
set(PYTHON_BINDING_BUILD_PYTHON2_AND_PYTHON3_DEFAULT OFF)
option(PYTHON_BINDING_BUILD_PYTHON2_AND_PYTHON3 "Build Python 2 and Python 3 bindings" ${PYTHON_BINDING_BUILD_PYTHON2_AND_PYTHON3_DEFAULT})
if(${PYTHON_BINDING_FORCE_PYTHON2} AND ${PYTHON_BINDING_FORCE_PYTHON3})
  message(FATAL_ERROR "Cannot enforce Python 2 and Python 3 at the same time")
endif()

###########################
# -- Clone destination -- #
###########################
option(GET_SOURCE_IN_SOURCE "Get all sources in ${PROJECT_SOURCE_DIR} instead of ${PROJECT_BINARY_DIR}" OFF)
