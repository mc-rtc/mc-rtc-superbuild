# Download a file to the given file and error immediately if the download fails
function(DownloadFile URL DESTINATION EXPECTED_SHA256)
  file(DOWNLOAD "${URL}" "${DESTINATION}" EXPECTED_HASH SHA256=${EXPECTED_SHA256} SHOW_PROGRESS STATUS DOWNLOAD_STATUS)
  list(GET DOWNLOAD_STATUS 0 STATUS_CODE)
  if(NOT ${STATUS_CODE} EQUAL 0)
    list(GET DOWNLOAD_STATUS 1 ERROR_MESSAGE)
    message(FATAL_ERROR "Download of ${DESTINATION} failed: ${ERROR_MESSAGE}")
  endif()
endfunction()
