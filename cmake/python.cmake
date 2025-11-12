# Usage example (after DISTRO and MC_RTC_SUPERBUILD_DEFAULT_PYTHON are set):
# handle_noble_virtualenv(${MC_RTC_SUPERBUILD_DEFAULT_PYTHON} ${DISTRO})
macro(handle_noble_virtualenv PYTHON_EXEC DISTRO)
  if(${DISTRO} STREQUAL "noble")
    # Check if we are already in a virtualenv
    execute_process(
      COMMAND ${PYTHON_EXEC} -c "import sys; exit(0) if (hasattr(sys, 'real_prefix') or (getattr(sys, 'base_prefix', sys.prefix) != sys.prefix)) else exit(1)"
      RESULT_VARIABLE IN_VENV # 0 if in venv, 1 otherwise
    )
    if(IN_VENV EQUAL 0 # we are in a venv
       AND ENV{VIRTUAL_ENV} STREQUAL ${MC_RTC_SUPERBUILD_VENV_NAME} # and the active venv matches the expected one
     )
     message(STATUS "Already in the expected Python virtualenv: ${MC_RTC_SUPERBUILD_VENV_NAME}")
    else()
      set(VENV_PATH "${CMAKE_INSTALL_PREFIX}/${MC_RTC_SUPERBUILD_VENV_NAME}")
      message(STATUS "Creating Python virtualenv at ${VENV_PATH} for Ubuntu Noble")
      execute_process(
        COMMAND ${PYTHON_EXEC} -m venv "${VENV_PATH}"
        RESULT_VARIABLE VENV_RESULT
      )
      if(NOT VENV_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to create Python virtualenv at ${VENV_PATH}")
      endif()
      # Re-execute python from the venv for subsequent pip installs
      set(MC_RTC_SUPERBUILD_DEFAULT_PYTHON "${VENV_PATH}/bin/python" CACHE INTERNAL "")
      # "Activate" the venv for subsequent commands by setting Python and pip paths
      set(MC_RTC_SUPERBUILD_DEFAULT_PIP "${VENV_PATH}/bin/pip" CACHE INTERNAL "")
      # set environment variables for subprocesses
      set(ENV{VIRTUAL_ENV} "${VENV_PATH}")
      set(ENV{PATH} "${VENV_PATH}/bin:$ENV{PATH}")
    endif()
  endif()
endmacro()

