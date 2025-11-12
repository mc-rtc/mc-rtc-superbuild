macro(detect_distro OUT_VAR)
  find_program(LSB_RELEASE lsb_release)
  if(NOT LSB_RELEASE)
    message(FATAL_ERROR "lsb_release must be installed before running this script")
  endif()
  execute_process(
    COMMAND lsb_release -sc
    OUTPUT_VARIABLE ${OUT_VAR}
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
endmacro()

detect_distro(DISTRO)
