file(GLOB robots CONFIGURE_DEPENDS "*.cmake")

foreach(robot ${robots})
  include("${robot}")
endforeach()
