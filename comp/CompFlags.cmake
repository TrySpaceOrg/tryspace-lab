# TrySpace-Lab Component Settings
include(CheckCCompilerFlag)

# Allow callers to skip applying these component flags by setting
# the CMake variable TRYSPACE_SKIP_COMP_FLAGS to TRUE.
if(ENABLE_UNIT_TESTS)
    set(TRYSPACE_C_FLAGS
        # --- Diagnostics and coverage ---
        "-fdiagnostics-show-option"     # Show warning/diagnostic option in output
        "-fprofile-arcs"                # Code coverage (gcov)
        "-ftest-coverage"               # Code coverage (gcov)
    )
else()
    set(TRYSPACE_C_FLAGS
        # --- Core warnings and strictness ---
        "-Wall"                         # Enable all common warnings
        "-Werror"                       # Treat warnings as errors
        "-Wextra"                       # Enable extra warnings
        "-Wpedantic"                    # Enforce standard compliance
        "-Wformat=2"                    # Strict format string checking
        "-Wconversion"                  # Warn on implicit type conversions
        "-Wsign-conversion"             # Warn on sign conversions
        "-Wshadow"                      # Warn about variable shadowing
        "-Wpointer-arith"               # Warn about pointer arithmetic on void* and function pointers
        "-Wcast-align"                  # Warn about cast alignment issues
        "-Wstrict-prototypes"           # Warn about missing function prototypes
        "-Wmissing-prototypes"          # Warn about missing prototypes in files
        "-Wmissing-declarations"        # Warn about missing declarations
        "-Wredundant-decls"             # Warn about redundant declarations
        "-Wwrite-strings"               # Make string literals const char*
        "-Wuninitialized"               # Warn about uninitialized variables
        "-Winit-self"                   # Warn about variables initialized with themselves
        "-Wswitch-default"              # Warn if switch statement does not have a default case
        "-Wswitch-enum"                 # Warn if switch on enum does not handle all values
        "-Wfloat-equal"                 # Warn about comparing floating point values for equality
        "-Wbad-function-cast"           # Warn about bad function casts

        # --- Suppressions and compatibility ---
        "-Wno-discarded-qualifiers"     # Suppress warnings about discarded qualifiers
        "-Wno-packed"                   # Suppress warnings about packed attribute
        "-Wno-unused-parameter"         # Suppress warnings about unused parameters

        # --- Overflow and macros ---
        "-Wstrict-overflow"             # Warn about code that may have strict overflow issues
        "-Wstrict-overflow=5"           # Maximum strict overflow warnings
        "-Wvariadic-macros"             # Warn about variadic macros
        "-Wvla"                         # Warn about use of variable length arrays

        # --- Standard enforcement ---
        "-pedantic-errors"              # Make all pedantic warnings into errors

        # --- Optimization and safety ---
        "-O2"                           # Optimize for speed (use -O3 for max, -Og for debug)
        "-std=c99"                      # Enforce C99 standard (or use -std=c11)
        "-D_FORTIFY_SOURCE=2"           # Enable buffer overflow protection (if supported)
        "-fstack-protector-strong"      # Enable stack protection
    )
endif()

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
