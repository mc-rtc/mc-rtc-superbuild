# Recursive remove folders between SOURCE_DIR and SOURCE_DESTINATION if they are empty
function(remove_if_empty DIR_VAR)
  file(GLOB FILES ${${DIR_VAR}}/*)
  list(LENGTH FILES NFILES)
  if(NFILES EQUAL 0)
    file(REMOVE_RECURSE ${${DIR_VAR}})
    cmake_path(GET ${DIR_VAR} PARENT_PATH ${DIR_VAR})
    set(${DIR_VAR}
        ${${DIR_VAR}}
        PARENT_SCOPE
    )
  else()
    set(${DIR_VAR}
        ${SOURCE_DESTINATION}
        PARENT_SCOPE
    )
  endif()
endfunction()

while(NOT "${SOURCE_DIR}" STREQUAL "${SOURCE_DESTINATION}")
  remove_if_empty(SOURCE_DIR)
endwhile()
remove_if_empty(SOURCE_DESTINATION)
