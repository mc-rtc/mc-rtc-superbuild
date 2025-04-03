function(RequireExtension FOLDER)
  if(NOT EXISTS "${PROJECT_SOURCE_DIR}/extensions/${FOLDER}")
    include(FetchContent)
    FetchContent_Declare(
      ${FOLDER} ${ARGN} SOURCE_DIR "${PROJECT_SOURCE_DIR}/extensions/${FOLDER}"
    )
    FetchContent_Populate(${FOLDER})
  endif()
  addextension(${PROJECT_SOURCE_DIR}/extensions/${FOLDER})
endfunction()

function(AddExtension FOLDER)
  if(EXISTS "${FOLDER}/required-extensions.cmake")
    include("${FOLDER}/required-extensions.cmake")
  endif()
  get_property(ADDED_EXTENSIONS GLOBAL PROPERTY ADDED_EXTENSIONS)
  if(NOT ${FOLDER} IN_LIST ADDED_EXTENSIONS)
    set_property(GLOBAL APPEND PROPERTY ADDED_EXTENSIONS ${FOLDER})
    add_subdirectory(${FOLDER})
    if(EXISTS ${FOLDER}/.git)
      cmake_path(GET FOLDER FILENAME EXTENSION_NAME)
      add_custom_target(
        self-update-extension-${EXTENSION_NAME}
        COMMAND ${CMAKE_COMMAND} -DNAME=${EXTENSION_NAME} -DSOURCE_DIR=${FOLDER} -P
                ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/scripts/update-project.cmake
      )
      add_dependencies(self-update self-update-extension-${EXTENSION_NAME})
    endif()
  endif()
endfunction()
