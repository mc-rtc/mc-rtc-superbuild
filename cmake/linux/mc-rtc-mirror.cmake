include(CMakeDependentOption)

option(USE_MC_RTC_APT_MIRROR "Use mc-rtc apt mirror to install available packages" OFF)
cmake_dependent_option(
  USE_MC_RTC_APT_MIRROR_STABLE "Use mc-rtc/stable rather than mc-rtc/head" OFF
  "USE_MC_RTC_APT_MIRROR" OFF
)

function(SetupMcRtcMirror SELECTED ALTERNATIVE)
  if(EXISTS "/etc/apt/sources.list.d/mc-rtc-${ALTERNATIVE}.list")
    message(
      WARNING
        "mc-rtc/${ALTERNATIVE} was previously setup, setting up mc-rtc/${SELECTED} as requested, you might have some troubles"
    )
    execute_process(
      COMMAND sudo bash -c "rm -f /etc/apt/sources.list.d/mc-rtc-${ALTERNATIVE}.list"
    )
  endif()
  if(EXISTS "/etc/apt/sources.list.d/mc-rtc-${SELECTED}.list")
    return()
  endif()
  execute_process(
    COMMAND
      bash -c
      "curl -1sLf 'https://dl.cloudsmith.io/public/mc-rtc/${SELECTED}/setup.deb.sh' | sudo -E bash"
    RESULT_VARIABLE BASH_FAILED
  )
  if(BASH_FAILED)
    message(FATAL_ERROR "Failed to add mc-rtc/${SELECTED} mirror")
  endif()
endfunction()

if(USE_MC_RTC_APT_MIRROR)
  if(USE_MC_RTC_APT_MIRROR_STABLE)
    SetupMcRtcMirror(stable head)
  else()
    SetupMcRtcMirror(head stable)
  endif()
endif()
