option(WITH_URI "Build the Unified Robot Interface (uri manager/interface/viewer)" OFF)

if(NOT WITH_URI)
  return()
endif()

find_program(CARGO cargo HINTS "$ENV{HOME}/.cargo/bin")
if(NOT CARGO)
  message(STATUS "Installing a Rust toolchain with rustup (needed by zenoh-c)")
  execute_process(
    COMMAND
      bash -c
      "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal"
    RESULT_VARIABLE RUSTUP_FAILED
  )
  unset(CARGO CACHE)
  find_program(CARGO cargo HINTS "$ENV{HOME}/.cargo/bin")
  if(RUSTUP_FAILED OR NOT CARGO)
    message(FATAL_ERROR "Failed to install a Rust toolchain, see https://rustup.rs")
  endif()
endif()
get_filename_component(CARGO_DIR "${CARGO}" DIRECTORY)
set(ENV{PATH} "${CARGO_DIR}:$ENV{PATH}")

AptInstall(libcap2-bin)

AddProject(
  flatbuffers
  GITHUB google/flatbuffers
  GIT_TAG v25.12.19
  CMAKE_ARGS -DFLATBUFFERS_BUILD_TESTS=OFF
  SKIP_TEST
)

AddProject(
  zenoh-c
  GITHUB eclipse-zenoh/zenoh-c
  GIT_TAG 1.9.0
  CMAKE_ARGS -DZENOHC_BUILD_WITH_SHARED_MEMORY=ON
  SKIP_TEST
)

AddProject(
  zenoh-cpp
  GITHUB eclipse-zenoh/zenoh-cpp
  GIT_TAG 1.9.0
  CMAKE_ARGS -DZENOHCXX_ZENOHC=ON -DZENOHCXX_ZENOHPICO=OFF -DZENOHCXX_EXAMPLES=OFF
  DEPENDS zenoh-c
  SKIP_TEST
)

AddProject(
  uri
  GITHUB isri-aist/unified_robot_interface
  GIT_TAG origin/main
  CMAKE_ARGS -DBUILD_TESTING=OFF -DWITH_PROTOBUF=OFF
  DEPENDS mc_rtc flatbuffers zenoh-cpp
  SKIP_TEST
)
