if(NOT DEFINED SOURCE_DIR)
  message(FATAL_ERROR "SOURCE_DIR was not provided")
endif()

if(NOT DEFINED SELECTED_PACKAGES)
  message(FATAL_ERROR "SELECTED_PACKAGES was not provided")
endif()

string(REPLACE "," ";" SELECTED_PACKAGE_LIST "${SELECTED_PACKAGES}")

file(
  GLOB_RECURSE PACKAGE_XML_FILES
  LIST_DIRECTORIES false
  "${SOURCE_DIR}/package.xml" "${SOURCE_DIR}/*/package.xml"
  "${SOURCE_DIR}/*/*/package.xml" "${SOURCE_DIR}/*/*/*/package.xml"
)

foreach(PACKAGE_XML IN LISTS PACKAGE_XML_FILES)
  get_filename_component(PACKAGE_DIR "${PACKAGE_XML}" DIRECTORY)

  file(READ "${PACKAGE_XML}" PACKAGE_XML_CONTENT)

  string(REGEX MATCH "<name>[ \t\r\n]*([^<]+)[ \t\r\n]*</name>" PACKAGE_NAME_MATCH
               "${PACKAGE_XML_CONTENT}"
  )

  if(NOT PACKAGE_NAME_MATCH)
    message(WARNING "Could not determine package name from ${PACKAGE_XML}")
    continue()
  endif()

  set(PACKAGE_NAME "${CMAKE_MATCH_1}")

  string(STRIP "${PACKAGE_NAME}" PACKAGE_NAME)

  if(PACKAGE_NAME IN_LIST SELECTED_PACKAGE_LIST)
    file(REMOVE "${PACKAGE_DIR}/COLCON_IGNORE")

    message(STATUS "Colcon package enabled: ${PACKAGE_NAME}")
  else()
    file(WRITE "${PACKAGE_DIR}/COLCON_IGNORE" "")

    message(STATUS "Colcon package ignored: ${PACKAGE_NAME}")
  endif()
endforeach()
