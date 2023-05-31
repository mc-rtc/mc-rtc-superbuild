function(GetExtraPythonPath OUT_VAR)
  execute_process(
    COMMAND
    ${MC_RTC_SUPERBUILD_DEFAULT_PYTHON} -c
      "from distutils import sysconfig; print(sysconfig.get_python_lib(prefix = '${CMAKE_INSTALL_PREFIX}', plat_specific = True))"
    RESULT_VARIABLE PYTHON_INSTALL_DESTINATION_FOUND
    OUTPUT_VARIABLE PYTHON_INSTALL_DESTINATION
    OUTPUT_STRIP_TRAILING_WHITESPACE)
  # Debian/Ubuntu has a specific problem here See
  # https://github.com/mesonbuild/meson/issues/8739 for an overview of the
  # problem
  if(EXISTS /etc/debian_version)
    execute_process(
      COMMAND
        ${MC_RTC_SUPERBUILD_DEFAULT_PYTHON} -c
        "import sys; print(\"python{}.{}\".format(sys.version_info.major, sys.version_info.minor));"
      OUTPUT_VARIABLE PYTHON_VERSION
      OUTPUT_STRIP_TRAILING_WHITESPACE)
    string(REPLACE "python3/" "${PYTHON_VERSION}/"
                   PYTHON_INSTALL_DESTINATION
                   "${PYTHON_INSTALL_DESTINATION}")
  endif()
  set(${OUT_VAR} "${PYTHON_INSTALL_DESTINATION}" PARENT_SCOPE)
endfunction()

function(AddToPath DIR)
  if("$ENV{PATH}" MATCHES "${DIR}")
    return()
  endif()
  if(WIN32)
    set(ENV{PATH} "${DIR};$ENV{PATH}")
    if(MC_RTC_SUPERBUILD_SET_ENVIRONMENT)
      execute_process(COMMAND powershell -c "[System.Environment]::SetEnvironmentVariable('PATH', '${DIR};' + [System.Environment]::GetEnvironmentVariable('PATH', 'User'), 'User')" COMMAND_ERROR_IS_FATAL ANY)
      if(DEFINED ENV{GITHUB_ENV})
        file(APPEND "$ENV{GITHUB_ENV}" "PATH=$ENV{PATH}\n")
      endif()
    endif()
  else()
    set(ENV{PATH} "${DIR}:$ENV{PATH}")
  endif()
endfunction()

AddToPath("${CMAKE_INSTALL_PREFIX}/bin")
GetExtraPythonPath(EXTRA_PYTHONPATH)
if(NOT "$ENV{PYTHONPATH}" MATCHES "${EXTRA_PYTHONPATH}")
  if(WIN32)
    set(ENV{PYTHONPATH} "${EXTRA_PYTHONPATH};$ENV{PYTHONPATH}")
    execute_process(COMMAND powershell -c "[System.Environment]::SetEnvironmentVariable('PYTHONPATH', '${DIR};' + [System.Environment]::GetEnvironmentVariable('PYTHONPATH', 'User'), 'User')" COMMAND_ERROR_IS_FATAL ANY)
    if(DEFINED ENV{GITHUB_ENV})
      file(APPEND "$ENV{GITHUB_ENV}" "PYTHONPATH=$ENV{PYTHONPATH}\n")
    endif()
  else()
    set(ENV{PYTHONPATH} "${EXTRA_PYTHONPATH}:$ENV{PYTHONPATH}")
  endif()
endif()

if(APPLE)
  if(NOT "$ENV{DYLD_LIBRARY_PATH}" MATCHES "${CMAKE_INSTALL_PREFIX}/lib")
    set(ENV{DYLD_LIBRARY_PATH} "${CMAKE_INSTALL_PREFIX}/lib:$ENV{DYLD_LIBRARY_PATH}")
  endif()
elseif(UNIX)
  if(NOT "$ENV{LD_LIBRARY_PATH}" MATCHES "${CMAKE_INSTALL_PREFIX}/lib")
    set(ENV{LD_LIBRARY_PATH} "${CMAKE_INSTALL_PREFIX}/lib:$ENV{LD_LIBRARY_PATH}")
  endif()
endif()
