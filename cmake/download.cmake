# Download a file to the given file and error immediately if the download fails
function(DownloadFile URL DESTINATION EXPECTED_SHA256)
  if(DEFINED "${DESTINATION}_URL")
    if("${${DESTINATION}_URL}" STREQUAL "${URL}" AND DEFINED
                                                     "${DESTINATION}_DOWNLOAD_OK"
    )
      return()
    endif()
  endif()
  unset(${DESTINATION}_DOWNLOAD_OK CACHE)
  set(${DESTINATION}_URL
      "${URL}"
      CACHE INTERNAL "Url to get ${DESTINATION}"
  )
  set(MAX_ATTEMPTS 5)
  set(ATTEMPT_I 1)
  while(${ATTEMPT_I} LESS_EQUAL ${MAX_ATTEMPTS})
    file(
      DOWNLOAD "${URL}" "${DESTINATION}"
      SHOW_PROGRESS
      STATUS DOWNLOAD_STATUS
      LOG DOWNLOAD_LOG
    )
    list(GET DOWNLOAD_STATUS 0 STATUS_CODE)
    if(${STATUS_CODE} EQUAL 0)
      if("${DOWNLOAD_HASH}" STREQUAL "")
        set(${DESTINATION}_DOWNLOAD_OK
            ON
            CACHE INTERNAL "${DESTINATION} download success"
        )
        break()
      else()
        file(SHA256 "${DESTINATION}" DOWNLOAD_HASH)
        if("${DOWNLOAD_HASH}" STREQUAL "${EXPECTED_SHA256}")
          set(${DESTINATION}_DOWNLOAD_OK
              ON
              CACHE INTERNAL "${DESTINATION} download success"
          )
          break()
        else()
          message(
            "Missmatched SHA256, expected ${EXPECTED_SHA256} but got ${DOWNLOAD_HASH}"
          )
        endif()
      endif()
    endif()
    file(REMOVE "${DESTINATION}")
    list(GET DOWNLOAD_STATUS 1 ERROR_MESSAGE)
    math(EXPR ATTEMPT_I "${ATTEMPT_I} + 1")
    if(${ATTEMPT_I} LESS ${MAX_ATTEMPTS})
      message("Download failed, attempt ${ATTEMPT_I} out of ${MAX_ATTEMPTS}")
      message("Failure message: ${ERROR_MESSAGE}")
    else()
      message("Download failed ${MAX_ATTEMPTS} times")
      message("Final download log:")
      message("${DOWNLOAD_LOG}")
      message(FATAL_ERROR "Download failed, see logs above")
    endif()
  endwhile()
endfunction()
