if(NOT USE_SUDO)
  set(SUDO_CMD "")
else()
  set(SUDO_CMD ${SUDO_CMD} -E)
endif()

if(EXISTS "${BINARY_DIR}/install_manifest.txt")
  # First we try to invoke the uninstall target
  execute_process(
    COMMAND ${SUDO_CMD} ${CMAKE_COMMAND} --build "${BINARY_DIR}" --target uninstall
    ERROR_QUIET
  )
  # If the file still exists we do what the uninstall target does in jrl-cmakemodules
  if(EXISTS "${BINARY_DIR}/install_manifest.txt")
    file(READ "${BINARY_DIR}/install_manifest.txt" files)
    string(REGEX REPLACE "\n" ";" files "${files}")
    list(REMOVE_ITEM files "")
    list(REVERSE files)
    foreach(file ${files})
      message(STATUS "Uninstalling \"${file}\"")
      execute_process(COMMAND ${SUDO_CMD} ${CMAKE_COMMAND} -E rm -f "${file}")
      if(file MATCHES ".py$")
        set(pycfile "${file}c")
        if(EXISTS "${pycfile}")
          execute_process(COMMAND ${SUDO_CMD} ${CMAKE_COMMAND} -E rm -f "${pycfile}")
        endif()
      endif()
    endforeach()
    execute_process(COMMAND ${SUDO_CMD} ${CMAKE_COMMAND} -E rm -f "${BINARY_DIR}/install_manifest.txt")
  endif()
  # Remove the install stamp
  execute_process(COMMAND ${CMAKE_COMMAND} -E rm -f "${INSTALL_STAMP}")
endif()
