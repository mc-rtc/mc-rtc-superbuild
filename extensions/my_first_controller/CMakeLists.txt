# The controller is made based on the tutorial "Your first controller with mc_rtc" on mc_rtc website
# https://arntanguy.github.io/mc_rtc/tutorials/introduction/first-controller.html

cmake_minimum_required(VERSION 3.10)

set(CXX_DISABLE_WERROR 1)
set(CMAKE_CXX_STANDARD 11)

set(PROJECT_NAME MyFirstController)
set(PROJECT_DESCRIPTION "MyFirstController")
set(PROJECT_URL "")

project(${PROJECT_NAME} CXX)

# Check if the project is built inside mc_rtc
if(NOT TARGET mc_rtc::mc_control)
  find_package(mc_rtc REQUIRED)
endif()

add_subdirectory(src)

set(AROBASE "@")
configure_file(etc/MyFirstController.in.yaml "${CMAKE_CURRENT_BINARY_DIR}/etc/MyFirstController.yaml")
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/etc/MyFirstController.yaml" DESTINATION "${MC_CONTROLLER_RUNTIME_INSTALL_PREFIX}/etc")

