execute_process(
  COMMAND
    ${MC_RTC_SUPERBUILD_DEFAULT_PYTHON} -c
    "import sys; print(\"python{}.{}\".format(sys.version_info.major, sys.version_info.minor));"
  OUTPUT_VARIABLE PYTHON_VERSION
  OUTPUT_STRIP_TRAILING_WHITESPACE
)

set(ENV{PYTHONPATH}
    "${CMAKE_INSTALL_PREFIX}/lib/${PYTHON_VERSION}/site-packages:$ENV{PYTHONPATH}"
)
set(ENV{PATH} "$ENV{VIRTUAL_ENV}/bin:$ENV{PATH}")
message(WARNING "python: PATH is $ENV{PATH}")
