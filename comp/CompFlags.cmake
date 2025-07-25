# TrySpace-Lab Component Settings
include(CheckCCompilerFlag)

set(TRYSPACE_C_FLAGS
    "-Wall"
    "-Wextra"
    "-Wpedantic"
    "-Wformat=2"
    "-Wno-discarded-qualifiers"
    "-Winline"
    "-Wpointer-arith"
    "-Wredundant-decls"
    "-Wwrite-strings"
    "-Wuninitialized"
    "-Winit-self"
    "-Wswitch-default"
    "-Wfloat-equal"
    "-Wno-packed"
    "-Wno-unused-parameter"
    "-Wvariadic-macros"
    "-Wvla"
    "-Wstrict-overflow"
    "-Wstrict-overflow=5"
    "-fdiagnostics-show-option"
    "-pedantic-errors"
    "-fprofile-arcs"
    "-ftest-coverage"
)

# Example: Add target-specific flags
# if(${TGTNAME} STREQUAL cpu1)
#     list(APPEND TRYSPACE_C_FLAGS "-Wformat=0")
# endif()

# GCC-only flags
if(CMAKE_COMPILER_IS_GNUCC)
    list(APPEND TRYSPACE_C_FLAGS "-Wlogical-op" "-Wunsafe-loop-optimizations")
endif()

# Convert list to string and append to CMAKE_C_FLAGS
string(REPLACE ";" " " TRYSPACE_C_FLAGS "${TRYSPACE_C_FLAGS}")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${TRYSPACE_C_FLAGS}")
