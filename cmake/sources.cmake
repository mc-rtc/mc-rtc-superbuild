set_property(GLOBAL PROPERTY MC_RTC_SUPERBUILD_SOURCES)

function(AddGitSource ID URI)
  if(NOT "${ID}" MATCHES "^[_A-Z]+$")
    message(
      FATAL_ERROR
        "[AddGitSource] Source ID can only contain uppercase letters and underscores"
    )
  endif()
  get_property(MC_RTC_SUPERBUILD_SOURCES GLOBAL PROPERTY MC_RTC_SUPERBUILD_SOURCES)
  list(FIND MC_RTC_SUPERBUILD_SOURCES "${ID}" TMP)
  if(TMP GREATER_EQUAL 0)
    message(FATAL_ERROR "[AddGitSource] ${ID} has already been registered")
  endif()
  set_property(GLOBAL APPEND PROPERTY MC_RTC_SUPERBUILD_SOURCES "${ID}")
  set_property(GLOBAL PROPERTY MC_RTC_SUPERBUILD_SOURCES_${ID} "${URI}")
endfunction()

AddGitSource(GIT_REPOSITORY "")
AddGitSource(GITHUB https://github.com/)
AddGitSource(GITHUB_PRIVATE git@github.com:)
AddGitSource(GITE git@gite.lirmm.fr:)
