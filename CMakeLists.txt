cmake_minimum_required(VERSION 3.29)

# Disable modules support, this is broken with clang-tidy at the moment
cmake_policy(SET CMP0155 OLD) 

if (NOT DEFINED CMAKE_VS_PLATFORM_NAME)
  set(CMAKE_VS_PLATFORM_NAME x64)
endif()

# This template attempts to be "fetch_content"-able
# so that it works well with tools like CPM or other
# manual dependency management

# Only set the cxx_standard if it is not set by someone else
if (NOT DEFINED CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 20)
endif()

# strongly encouraged to enable this globally to avoid conflicts between
# -Wpedantic being enabled and -std=c++20 and -std=gnu++20 for example
# when compiling with PCH enabled
set(CMAKE_CXX_EXTENSIONS OFF)

# Set the project name and language
project(
  GAP
  VERSION 0.0.2
  DESCRIPTION ""
  HOMEPAGE_URL "https://github.com/NiNeDelixe/GAP"
  LANGUAGES CXX C)

include(cmake/PreventInSourceBuilds.cmake)
include(cmake/Emscripten.cmake)
include(ProjectOptions.cmake)


GAP_setup_options()

if (GAP_WARNINGS_AS_ERRORS)
  set(GAP_WARNING_TYPE SEND_ERROR)
else()
  set(GAP_WARNING_TYPE WARNING)
endif()

GAP_global_options()

# sherpa-onnx force-sets BUILD_TESTING=OFF in the cache via its Eigen dependency,
# so remember the user's choice and restore it once dependencies are set up
set(GAP_SAVED_BUILD_TESTING ON)
if(DEFINED BUILD_TESTING)
  set(GAP_SAVED_BUILD_TESTING "${BUILD_TESTING}")
endif()

# sherpa-onnx v1.13.8's sources assume C++17 semantics (u8 string literals
# stop converting to const char* under C++20), so scope the dependency
# subtree to C++17 and restore the project's choice afterwards
if(DEFINED CMAKE_CXX_STANDARD)
  set(GAP_SAVED_CXX_STANDARD "${CMAKE_CXX_STANDARD}")
endif()
set(CMAKE_CXX_STANDARD 17)

include(Dependencies.cmake)
GAP_setup_dependencies()

set(BUILD_TESTING "${GAP_SAVED_BUILD_TESTING}" CACHE BOOL "" FORCE)
if(DEFINED GAP_SAVED_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD "${GAP_SAVED_CXX_STANDARD}")
endif()

GAP_local_options()

# don't know if this should be set globally from here or not...
set(CMAKE_CXX_VISIBILITY_PRESET hidden)

set(GIT_SHA
    "Unknown"
    CACHE STRING "SHA this build was generated from")
string(
  SUBSTRING "${GIT_SHA}"
            0
            8
            GIT_SHORT_SHA)

target_compile_features(GAP_options INTERFACE cxx_std_${CMAKE_CXX_STANDARD})

add_library(GAP::GAP_options ALIAS GAP_options)
add_library(GAP::GAP_warnings ALIAS GAP_warnings)

#add_library(GAP::GAP_options INTERFACE IMPORTED)
#add_library(GAP::GAP_warnings INTERFACE IMPORTED)

# configure files based on CMake configuration options
add_subdirectory(configured_files)

# Adding the src:
add_subdirectory(src)

# Create unified web deployment directory (for WASM builds)
if(EMSCRIPTEN)
  GAP_create_web_dist()
endif()

# Don't even look at tests if we're not top level
if(NOT PROJECT_IS_TOP_LEVEL)
  return()
endif()

# Adding the tests:
include(CTest)

if(BUILD_TESTING)
  message(AUTHOR_WARNING "Building Tests. Be sure to check out test/constexpr_tests.cpp for constexpr testing")
  add_subdirectory(test)
endif()


if(GAP_BUILD_FUZZ_TESTS)
  message(AUTHOR_WARNING "Building Fuzz Tests, using fuzzing sanitizer https://www.llvm.org/docs/LibFuzzer.html")
  if (NOT GAP_ENABLE_SANITIZER_ADDRESS AND NOT GAP_ENABLE_SANITIZER_THREAD)
    message(WARNING "You need asan or tsan enabled for meaningful fuzz testing")
  endif()
  add_subdirectory(fuzz_test)

endif()

# If MSVC is being used, and ASAN is enabled, we need to set the debugger environment
# so that it behaves well with MSVC's debugger, and we can run the target from visual studio
if(MSVC)
  get_all_installable_targets(all_targets)
  message("all_targets=${all_targets}")
  set_target_properties(${all_targets} PROPERTIES VS_DEBUGGER_ENVIRONMENT "PATH=$(VC_ExecutablePath_x64);%PATH%")
endif()

# set the startup project for the "play" button in MSVC
set_property(DIRECTORY PROPERTY VS_STARTUP_PROJECT intro)

if(CMAKE_SKIP_INSTALL_RULES)
  return()
endif()

include(cmake/PackageProject.cmake)

# Add other targets that you want installed here, by default we just package the one executable
# we know we want to ship
# GAP_package_project(
#   TARGETS
#   intro
#   GAP_options
#   GAP_warnings
#   # FIXME: this does not work! CK
#   # PRIVATE_DEPENDENCIES_CONFIGURED project_options project_warnings
# )

# Experience shows that explicit package naming can help make it easier to sort
# out potential ABI related issues before they start, while helping you
# track a build to a specific GIT SHA
set(CPACK_PACKAGE_FILE_NAME
    "${CMAKE_PROJECT_NAME}-${CMAKE_PROJECT_VERSION}-${GIT_SHORT_SHA}-${CMAKE_SYSTEM_NAME}-${CMAKE_BUILD_TYPE}-${CMAKE_CXX_COMPILER_ID}-${CMAKE_CXX_COMPILER_VERSION}"
)

include(CPack)
