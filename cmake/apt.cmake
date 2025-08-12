function(AptInstallNow)
  if(NOT DPKG)
    return()
  endif()
  execute_process(
    COMMAND dpkg-query -W ${ARGV}
    OUTPUT_QUIET ERROR_QUIET
    RESULT_VARIABLE MISSING_DEPS
  )
  if(MISSING_DEPS)
    message(STATUS "Install missing dependencies")
    execute_process(COMMAND sudo apt-get update RESULT_VARIABLE APT_FAILED)
    if(APT_FAILED)
      message(FATAL_ERROR "apt update failed, check the error and try again")
    endif()
    execute_process(
      COMMAND sudo -E apt-get install -y --no-install-recommends ${ARGV}
      RESULT_VARIABLE APT_FAILED
    )
    if(APT_FAILED)
      message(FATAL_ERROR "apt install failed, check the error and try again")
    endif()
  endif()
endfunction()

set_property(GLOBAL PROPERTY APT_INSTALL_PACKAGES)

function(FinalizeAptInstall)
  get_property(APT_INSTALL_PACKAGES GLOBAL PROPERTY APT_INSTALL_PACKAGES)
  list(LENGTH APT_INSTALL_PACKAGES NPACKAGES)
  if(NOT NPACKAGES EQUAL 0)
    AptInstallNow(${APT_INSTALL_PACKAGES})
  endif()
endfunction()

cmake_language(DEFER DIRECTORY ${PROJECT_SOURCE_DIR} CALL FinalizeAptInstall)

function(AptInstall)
  set_property(GLOBAL APPEND PROPERTY APT_INSTALL_PACKAGES ${ARGV})
endfunction()
