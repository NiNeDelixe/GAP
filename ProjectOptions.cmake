include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


include(CheckCXXSourceCompiles)


macro(GAP_supports_sanitizers)
  # Emscripten doesn't support sanitizers
  if(EMSCRIPTEN)
    set(SUPPORTS_UBSAN OFF)
    set(SUPPORTS_ASAN OFF)
  elseif((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)

    message(STATUS "Sanity checking UndefinedBehaviorSanitizer, it should be supported on this platform")
    set(TEST_PROGRAM "int main() { return 0; }")

    # Check if UndefinedBehaviorSanitizer works at link time
    set(CMAKE_REQUIRED_FLAGS "-fsanitize=undefined")
    set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=undefined")
    check_cxx_source_compiles("${TEST_PROGRAM}" HAS_UBSAN_LINK_SUPPORT)

    if(HAS_UBSAN_LINK_SUPPORT)
      message(STATUS "UndefinedBehaviorSanitizer is supported at both compile and link time.")
      set(SUPPORTS_UBSAN ON)
    else()
      message(WARNING "UndefinedBehaviorSanitizer is NOT supported at link time.")
      set(SUPPORTS_UBSAN OFF)
    endif()
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    if (NOT WIN32)
      message(STATUS "Sanity checking AddressSanitizer, it should be supported on this platform")
      set(TEST_PROGRAM "int main() { return 0; }")

      # Check if AddressSanitizer works at link time
      set(CMAKE_REQUIRED_FLAGS "-fsanitize=address")
      set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=address")
      check_cxx_source_compiles("${TEST_PROGRAM}" HAS_ASAN_LINK_SUPPORT)

      if(HAS_ASAN_LINK_SUPPORT)
        message(STATUS "AddressSanitizer is supported at both compile and link time.")
        set(SUPPORTS_ASAN ON)
      else()
        message(WARNING "AddressSanitizer is NOT supported at link time.")
        set(SUPPORTS_ASAN OFF)
      endif()
    else()
      set(SUPPORTS_ASAN ON)
    endif()
  endif()
endmacro()

macro(GAP_setup_options)
  option(GAP_ENABLE_HARDENING "Enable hardening" ON)
  option(GAP_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    GAP_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    GAP_ENABLE_HARDENING
    OFF)

  GAP_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR GAP_PACKAGING_MAINTAINER_MODE)
    option(GAP_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(GAP_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(GAP_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(GAP_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(GAP_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(GAP_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(GAP_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(GAP_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(GAP_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(GAP_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(GAP_ENABLE_PCH "Enable precompiled headers" OFF)
    option(GAP_ENABLE_CACHE "Enable ccache" OFF)
  elseif(ENABLE_DEVELOPER_MODE)
    option(GAP_ENABLE_IPO "Enable IPO/LTO" ON)
    option(GAP_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(GAP_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(GAP_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(GAP_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(GAP_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(GAP_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(GAP_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(GAP_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(GAP_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(GAP_ENABLE_PCH "Enable precompiled headers" OFF)
    option(GAP_ENABLE_CACHE "Enable ccache" ON)
  else()
    option(GAP_ENABLE_IPO "Enable IPO/LTO" ON)
    option(GAP_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(GAP_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(GAP_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(GAP_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(GAP_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(GAP_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(GAP_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(GAP_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(GAP_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(GAP_ENABLE_PCH "Enable precompiled headers" OFF)
    option(GAP_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      GAP_ENABLE_IPO
      GAP_WARNINGS_AS_ERRORS
      GAP_ENABLE_SANITIZER_ADDRESS
      GAP_ENABLE_SANITIZER_LEAK
      GAP_ENABLE_SANITIZER_UNDEFINED
      GAP_ENABLE_SANITIZER_THREAD
      GAP_ENABLE_SANITIZER_MEMORY
      GAP_ENABLE_UNITY_BUILD
      GAP_ENABLE_CLANG_TIDY
      GAP_ENABLE_CPPCHECK
      GAP_ENABLE_LIZARD
      GAP_ENABLE_BLOATY
      GAP_ENABLE_COVERAGE
      GAP_ENABLE_PCH
      GAP_ENABLE_CACHE)
  endif()

  GAP_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (GAP_ENABLE_SANITIZER_ADDRESS OR GAP_ENABLE_SANITIZER_THREAD OR GAP_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(GAP_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(GAP_global_options)
  if(GAP_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    GAP_enable_ipo()
  endif()

  GAP_supports_sanitizers()

  if(GAP_ENABLE_HARDENING AND GAP_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR GAP_ENABLE_SANITIZER_UNDEFINED
       OR GAP_ENABLE_SANITIZER_ADDRESS
       OR GAP_ENABLE_SANITIZER_THREAD
       OR GAP_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${GAP_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${GAP_ENABLE_SANITIZER_UNDEFINED}")
    GAP_enable_hardening(GAP_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(GAP_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(GAP_warnings INTERFACE)
  add_library(GAP_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  GAP_set_project_warnings(
    GAP_warnings
    ${GAP_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  include(cmake/Linker.cmake)
  # Must configure each target with linker options, we're avoiding setting it globally for now

  if(NOT EMSCRIPTEN)
    include(cmake/Sanitizers.cmake)
    GAP_enable_sanitizers(
      GAP_options
      ${GAP_ENABLE_SANITIZER_ADDRESS}
      ${GAP_ENABLE_SANITIZER_LEAK}
      ${GAP_ENABLE_SANITIZER_UNDEFINED}
      ${GAP_ENABLE_SANITIZER_THREAD}
      ${GAP_ENABLE_SANITIZER_MEMORY})
  endif()

  set_target_properties(GAP_options PROPERTIES UNITY_BUILD ${GAP_ENABLE_UNITY_BUILD})

  if(GAP_ENABLE_PCH)
    target_precompile_headers(
      GAP_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(GAP_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    GAP_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(GAP_ENABLE_CLANG_TIDY)
    GAP_enable_clang_tidy(GAP_options ${GAP_WARNINGS_AS_ERRORS})
  endif()

  if(GAP_ENABLE_CPPCHECK)
    GAP_enable_cppcheck(${GAP_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()
  
  if(GAP_ENABLE_LIZARD)
    GAP_enable_lizard(${GAP_WARNINGS_AS_ERRORS})
  endif()
  
  if(GAP_ENABLE_BLOATY)
    GAP_enable_bloaty()
  endif()

  if(GAP_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    GAP_enable_coverage(GAP_options)
  endif()

  if(GAP_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(GAP_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(GAP_ENABLE_HARDENING AND NOT GAP_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR GAP_ENABLE_SANITIZER_UNDEFINED
       OR GAP_ENABLE_SANITIZER_ADDRESS
       OR GAP_ENABLE_SANITIZER_THREAD
       OR GAP_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    GAP_enable_hardening(GAP_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
