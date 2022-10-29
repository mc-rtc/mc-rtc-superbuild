if(NOT DEFINED MSVC_TOOLSET_VERSION)
  message(FATAL_ERROR "This tool assumes you are using MSVC to build under Windows, please revise win32-dependencies.cmake to handle your toolset")
endif()

if(NOT ${CMAKE_SYSTEM_PROCESSOR} STREQUAL "AMD64")
  message(FATAL_ERROR "Only 64 bits builds are currently supported by this tool")
endif()

if(NOT DEFINED ENV{BOOST_ROOT} OR NOT EXISTS "$ENV{BOOST_ROOT}")
  set(BOOST_VERSION "1.77.0")
  string(REPLACE "." "_" BOOST_VERSION_ "${BOOST_VERSION}")
  if(${MSVC_TOOLSET_VERSION} EQUAL 141) # VS 2017
    set(MSVC_TOOLSET_VERSION_DOT "14.1")
    set(BOOST_BINARIES_SHA256 0dec1fb76276c3c0400609223ac60448122c75b398ddff60732c450c4fc729ff)
  #FIXME 1.77.0 does not come with 14.3 version, we bet on 14.2 version working
  elseif(${MSVC_TOOLSET_VERSION} EQUAL 142 OR ${MSVC_TOOLSET_VERSION} EQUAL 143) # VS 2019 or VS2022
    set(MSVC_TOOLSET_VERSION_DOT "14.2")
    set(BOOST_BINARIES_SHA256 8cf6bb866ff83922b19a7418e94bc1fce87cae0dea6077624e44de3c6e27505a)
  else()
    if(${MSVC_TOOLSET_VERSION} LESS 141)
      message(FATAL_ERROR "Your version of Visual Studio is too old. Upgrade to VS 2017 or later.")
    else()
      message(FATAL_ERROR "It seems your version of Visual Studio is recent. Please contact mc_rtc maintainers.")
    endif()
  endif()

  set(BOOST_ROOT "${CMAKE_CURRENT_BINARY_DIR}/Boost/${BOOST_VERSION}/x86_64")
  if(NOT EXISTS "${BOOST_ROOT}")
    set(BOOST_BINARIES "https://sourceforge.net/projects/boost/files/boost-binaries/${BOOST_VERSION}/boost_${BOOST_VERSION_}-msvc-${MSVC_TOOLSET_VERSION_DOT}-64.exe")
    message(STATUS "Downloading Boost binaries: ${BOOST_BINARIES}")
    set(BOOST_EXE_OUT "${CMAKE_CURRENT_BINARY_DIR}/boost_${BOOST_VERSION_}.exe")
    DownloadFile("${BOOST_BINARIES}" "${BOOST_EXE_OUT}" ${BOOST_BINARIES_SHA256})
    execute_process(COMMAND "${BOOST_EXE_OUT}" /SILENT /SP- /SUPPRESSMSGBOXES "/DIR=${BOOST_ROOT}")
  endif()

  set(ENV{BOOST_ROOT} "${BOOST_ROOT}")
  if(MC_RTC_SUPERBUILD_SET_ENVIRONMENT)
    execute_process(COMMAND powershell -c "[System.Environment]::SetEnvironmentVariable('BOOST_ROOT', '${BOOST_ROOT}', 'User')" COMMAND_ERROR_IS_FATAL ANY)
    if(DEFINED ENV{GITHUB_ENV})
      file(APPEND "$ENV{GITHUB_ENV}" "BOOST_ROOT=$ENV{BOOST_ROOT}\n")
    endif()
  endif()
  AddToPath("${BOOST_ROOT}/lib64-msvc-${MSVC_TOOLSET_VERSION_DOT}")
else()
  message("-- Boost install: $ENV{BOOST_ROOT}")
endif()

set(NEED_MINGW ON)
find_program(GFORTRAN gfortran.exe)
find_program(MINGW_MAKE mingw32-make.exe)
if(GFORTRAN AND MINGW_MAKE)
  cmake_path(GET GFORTRAN PARENT_PATH GFORTRAN_PATH)
  cmake_path(GET MINGW_MAKE PARENT_PATH MINGW_MAKE_PATH)
  if("${GFORTRAN_PATH}" STREQUAL "${MINGW_MAKE_PATH}")
    set(NEED_MINGW OFF)
    set(MINGW_PATH "${GFORTRAN_PATH}")
  endif()
endif()
if(NEED_MINGW)
  if(NOT EXISTS "${CMAKE_CURRENT_BINARY_DIR}/mingw64/bin/gfortran.exe")
    set(MINGW_URL "https://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win64/Personal%20Builds/mingw-builds/8.1.0/threads-win32/seh/x86_64-8.1.0-release-win32-seh-rt_v6-rev0.7z")
    set(MINGW_SHA256 73797b9a1d0b007dbdd6f010e6064dc0aa4df835b042f6947f73a3bf9cc348c5)
    message(STATUS "Downloading MinGW: ${MINGW_URL}")
    DownloadFile("${MINGW_URL}" "${CMAKE_CURRENT_BINARY_DIR}/mingw.7z" ${MINGW_SHA256})
    message(STATUS "Extract MinGW archive")
    file(ARCHIVE_EXTRACT INPUT "${CMAKE_CURRENT_BINARY_DIR}/mingw.7z" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")
    AddToPath("${CMAKE_CURRENT_BINARY_DIR}/mingw64/bin")
  endif()
else()
  message("-- MinGW install: ${MINGW_PATH}")
endif()

set(PIP_DEPENDENCIES
  Cython
  coverage
  nose
  pytest
  numpy
  matplotlib
  pyqt5
)
execute_process(COMMAND pip install --user ${PIP_DEPENDENCIES})

AddProject(eigen
  GITHUB eigenteam/eigen-git-mirror
  GIT_TAG 3.3.7
  SKIP_TEST
)
list(APPEND GLOBAL_DEPENDS eigen)

AddProject(tinyxml2
  GITHUB leethomason/tinyxml2
  GIT_TAG 7.1.0
  SKIP_TEST
)
list(APPEND GLOBAL_DEPENDS tinyxml2)

AddProject(geos
  GITHUB libgeos/geos
  GIT_TAG 3.10.1
  SKIP_TEST
)
list(APPEND GLOBAL_DEPENDS geos)

AddProject(nanomsg
  GITHUB nanomsg/nanomsg
  GIT_TAG 1.1.5
  SKIP_TEST
)
list(APPEND GLOBAL_DEPENDS nanomsg)

AddProject(yaml-cpp
  GITHUB jbeder/yaml-cpp
  GIT_TAG yaml-cpp-0.7.0
  CMAKE_ARGS -DYAML_CPP_BUILD_TESTS:BOOL=OFF
  SKIP_TEST
)
list(APPEND GLOBAL_DEPENDS yaml-cpp)

AddProject(spdlog
  GITHUB gabime/spdlog
  GIT_TAG v1.6.1
  CMAKE_ARGS -DSPDLOG_BUILD_EXAMPLE:BOOL=OFF -DSPDLOG_BUILD_SHARED:BOOL=ON
  SKIP_TEST
)
list(APPEND GLOBAL_DEPENDS spdlog)

if(BUILD_BENCHMARKS)
  AddProject(benchmark
    GITHUB google/benchmark
    CMAKE_ARGS -DBENCHMARK_ENABLE_GTEST_TESTS:BOOL=OFF
    SKIP_TEST
  )
  list(APPEND GLOBAL_DEPENDS benchmark)
endif()
