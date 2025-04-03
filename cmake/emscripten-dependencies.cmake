# Enforce some options
set(WITH_ROS_SUPPORT
    OFF
    CACHE BOOL "" FORCE
)
set(INSTALL_DOCUMENTATION
    OFF
    CACHE BOOL "" FORCE
)
set(BUILD_BENCHMARKS
    OFF
    CACHE BOOL "" FORCE
)
set(PYTHON_BINDING
    OFF
    CACHE BOOL "" FORCE
)
set(INSTALL_SYSTEM_DEPENDENCIES
    OFF
    CACHE BOOL "" FORCE
)
set(BUILD_TESTING
    OFF
    CACHE BOOL "" FORCE
)
set(CMAKE_BUILD_TYPE
    "Release"
    CACHE STRING "" FORCE
)

include(ProcessorCount)
ProcessorCount(NCPU)

AddProject(
  libf2c-emscripten
  GITHUB gergondet/libf2c-emscripten
  CONFIGURE_COMMAND ""
  BUILD_COMMAND
    ${CMAKE_COMMAND}
    -E
    chdir
    <SOURCE_DIR>
    emmake
    make
    -j${NCPU}
  INSTALL_COMMAND
    ${CMAKE_COMMAND}
    -E
    chdir
    <SOURCE_DIR>
    emmake
    make
    install
)
list(APPEND GLOBAL_DEPENDS libf2c-emscripten)

set(BOOST_VERSION "1.77.0")
set(BOOST_HASH "fc9f85fc030e233142908241af7a846e60630aa7388de9a5fafb1f3a26840854")

string(REPLACE "." "_" BOOST_VERSION_ "${BOOST_VERSION}")
set(BOOST_OUT "${CMAKE_CURRENT_BINARY_DIR}/boost_${BOOST_VERSION_}.tar.bz2")
DownloadFile(
  "https://boostorg.jfrog.io/artifactory/main/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION_}.tar.bz2"
  "${BOOST_OUT}"
  ${BOOST_HASH}
)
set(BOOST_SOURCE_DIR "${SOURCE_DESTINATION}/boost_${BOOST_VERSION_}")
if(NOT EXISTS "${BOOST_SOURCE_DIR}/boost.png")
  message(STATUS "Extracting Boost ${BOOST_VERSION} to ${SOURCE_DESTINATION}")
  file(ARCHIVE_EXTRACT INPUT "${BOOST_OUT}" DESTINATION "${SOURCE_DESTINATION}")
endif()
if(NOT EXISTS "${BOOST_SOURCE_DIR}/b2")
  execute_process(
    COMMAND ./bootstrap.sh WORKING_DIRECTORY "${BOOST_SOURCE_DIR}"
                                             COMMAND_ERROR_IS_FATAL ANY
  )
endif()
file(COPY cmake/emscripten/emscripten.jam
     DESTINATION "${BOOST_SOURCE_DIR}/tools/build/src/tools/"
)

set(b2_command
    ${CMAKE_COMMAND} -E chdir <SOURCE_DIR> emconfigure ./b2 toolset=emscripten
    --with-filesystem --with-program_options --with-serialization --with-system
    --with-timer --prefix=${CMAKE_INSTALL_PREFIX} variant=release link=static
)
AddProject(
  boost
  CONFIGURE_COMMAND "" SOURCE_DIR "${BOOST_SOURCE_DIR}" BINARY_DIR "${BOOST_SOURCE_DIR}"
  BUILD_COMMAND ${b2_command} stage
  INSTALL_COMMAND ${b2_command} install
)
list(APPEND GLOBAL_DEPENDS boost)

AddProject(
  eigen
  GITHUB eigenteam/eigen-git-mirror
  GIT_TAG 3.3.7 SKIP_TEST
  CMAKE_ARGS -DCMAKEPACKAGE_INSTALL_DIR=${CMAKE_INSTALL_PREFIX}/lib/cmake/Eigen3
)
list(APPEND GLOBAL_DEPENDS eigen)

AddProject(
  tinyxml2
  GITHUB leethomason/tinyxml2
  GIT_TAG 7.1.0 SKIP_TEST
)
list(APPEND GLOBAL_DEPENDS tinyxml2)

AddProject(
  geos
  GITHUB libgeos/geos
  GIT_TAG 3.10.1 SKIP_TEST
  CMAKE_ARGS -DBUILD_DOCUMENTATION=OFF -DBUILD_SHARED_LIBS=OFF -DDISABLE_GEOS_INLINE=ON
)
list(APPEND GLOBAL_DEPENDS geos)

AddProject(
  yaml-cpp
  GITHUB jbeder/yaml-cpp
  GIT_TAG yaml-cpp-0.7.0
  CMAKE_ARGS -DYAML_CPP_BUILD_TESTS:BOOL=OFF SKIP_TEST
)
list(APPEND GLOBAL_DEPENDS yaml-cpp)

AddProject(
  spdlog
  GITHUB gabime/spdlog
  GIT_TAG v1.6.1
  CMAKE_ARGS -DSPDLOG_BUILD_TESTS=OFF -DSPDLOG_BUILD_EXAMPLE:BOOL=OFF
                                      -DSPDLOG_BUILD_SHARED:BOOL=OFF SKIP_TEST
)
list(APPEND GLOBAL_DEPENDS spdlog)
