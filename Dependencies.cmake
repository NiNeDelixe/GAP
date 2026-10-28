include(cmake/CPM.cmake)

# Done as a function so that updates to variables like
# CMAKE_CXX_FLAGS don't propagate out to other
# targets
function(GAP_setup_dependencies)

  if(NOT DEFINED CPM_SOURCE_CACHE)
    set(CPM_SOURCE_CACHE "${CMAKE_BINARY_DIR}/.cache/CPM")
  endif()

  # For each dependency, see if it's
  # already been provided to us by a parent project

  if(NOT TARGET fmtlib::fmtlib)
    cpmaddpackage(
      NAME
      fmt
      GITHUB_REPOSITORY
      "fmtlib/fmt"
      GIT_TAG
      "12.1.0"
      SYSTEM
      YES)
  endif()

  if(NOT TARGET spdlog::spdlog)
    cpmaddpackage(
      NAME
      spdlog
      VERSION
      1.17.0
      GITHUB_REPOSITORY
      "gabime/spdlog"
      SYSTEM
      YES
      OPTIONS
      "SPDLOG_FMT_EXTERNAL ON")
  endif()

  if(NOT TARGET Catch2::Catch2WithMain)
    cpmaddpackage(
      NAME
      Catch2
      VERSION
      3.12.0
      GITHUB_REPOSITORY
      "catchorg/Catch2"
      SYSTEM
      YES)
  endif()

  if(NOT TARGET CLI11::CLI11)
    cpmaddpackage(
      NAME
      CLI11
      VERSION
      2.6.1
      GITHUB_REPOSITORY
      "CLIUtils/CLI11"
      SYSTEM
      YES)
  endif()

  if(NOT TARGET ftxui::screen)
    cpmaddpackage(
      NAME
      FTXUI
      VERSION
      6.1.9
      GITHUB_REPOSITORY
      "ArthurSonzogni/FTXUI"
      SYSTEM
      YES)
  endif()

  if(NOT TARGET tools::tools)
    cpmaddpackage(
      NAME
      tools
      GITHUB_REPOSITORY
      "lefticus/tools"
      GIT_TAG
      "main")
  endif()
  
  # if(NOT TARGET babylon)
  #   cpmaddpackage(
  #     NAME
  #     babylon
  #     GIT_TAG
  #     "main"
  #     GITHUB_REPOSITORY
  #     "Mobile-Artificial-Intelligence/babylon"
  #     SYSTEM
  #     YES)
  # endif()

#   if(NOT TARGET piper)
#     #set(ONNX_DISABLE_STATIC_REGISTRATION ON)
#     set(CMAKE_COMPILE_WARNING_AS_ERROR OFF)

#     CPMAddPackage(
#       NAME onnxruntime
#       GIT_TAG v1.22.2
#       GITHUB_REPOSITORY microsoft/onnxruntime
#       SYSTEM YES
#       SOURCE_SUBDIR cmake
#       OPTIONS
#       "onnxruntime_BUILD_UNIT_TESTS OFF"
#       "onnxruntime_ENABLE_PYTHON OFF"
#       "onnxruntime_USE_VCPKG ON"
#       "onnxruntime_DISABLE_ABSEIL ON"
#       "onnxruntime_USE_PREINSTALLED_EIGEN ON"
#       "onnxruntime_PREFER_SYSTEM_LIB OFF"
#     )
    
#     foreach(target
#     onnxruntime
#     onnxruntime_framework
#     onnxruntime_common
# )
#     if(TARGET ${target})
#         target_compile_options(${target} PRIVATE /WX-)
#     endif() 
#     endforeach()

#     if(TARGET onnxruntime_framework)
#     target_compile_options(onnxruntime_framework PRIVATE /wd4875)
# endif()

#     cpmaddpackage(
#       NAME piper
#       GIT_TAG "639388b6317fc4731e91d53da42aea68fd4166ff"
#       GITHUB_REPOSITORY OHF-Voice/piper1-gpl
#       SYSTEM YES
#       SOURCE_SUBDIR libpiper 
#       PATCHES "${CMAKE_CURRENT_SOURCE_DIR}\\patches\\piper-cmake-source-dir.patch"
#       OPTIONS
#       "PIPER_BUILD_SEPARATE_LIBS ON" 
#       #"ONNX_DISABLE_STATIC_REGISTRATION=ON"
#       )

#   endif()



  # add_compile_definitions(_USE_MATH_DEFINES)
  # add_compile_definitions(_CRT_SECURE_NO_WARNINGS)
  # add_compile_definitions(_CRT_NONSTDC_NO_DEPRECATE)
  # add_compile_definitions(_CRT_SECURE_NO_DEPRECATE)
  # #add_compile_options(/FIstdint.h)
  # #add_compile_options(-clang:-include -clang:stdint.h)

  if(NOT TARGET sherpa-onnx-cxx-api)
    add_compile_definitions(_USE_MATH_DEFINES)
    # openfst uses legacy CRT calls (_splitpath, strerror, _open, ...); /sdl
    # escalates the resulting C4996 deprecations to errors and /wd4996
    # cannot override /sdl, so suppress them at the source level instead
    add_compile_definitions(_CRT_SECURE_NO_WARNINGS _CRT_NONSTDC_NO_DEPRECATE)

    cpmaddpackage(
      NAME sherpa-onnx
      GIT_TAG "11afbd009a7f8c08f4bcf2fc1b265d0df4670fbf" # v1.13.8
      GITHUB_REPOSITORY k2-fsa/sherpa-onnx
      SYSTEM YES
      OPTIONS
      "SHERPA_ONNX_ENABLE_BINARY OFF"
      "SHERPA_ONNX_ENABLE_C_API ON"
      "SHERPA_ONNX_ENABLE_PORTAUDIO OFF"
      "SHERPA_ONNX_ENABLE_PYTHON OFF"
      "SHERPA_ONNX_ENABLE_SPEAKER_DIARIZATION OFF"
      "SHERPA_ONNX_ENABLE_TESTS OFF"
      "SHERPA_ONNX_ENABLE_TTS ON"
      "SHERPA_ONNX_ENABLE_WEBSOCKET OFF"
      "SHERPA_ONNX_USE_STATIC_CRT OFF")
  endif()

  if(NOT TARGET sherpa-onnx-cxx-api)
    message(FATAL_ERROR "sherpa-onnx did not provide its C++ API target")
  endif()

  # espeak-ng's compat/stdint.h breaks under clang-cl: its ../include/stdint.h
  # resolves to clang's builtin stdint.h wrapper (already include-guarded, so
  # empty), leaving uint32_t/uint64_t undefined. include_next skips clang's
  # builtin dir and reaches the real MSVC header, but cl.exe has no
  # include_next (fatal C1021), so the workaround is gated on __clang__.
  # Re-applied on every configure, so re-downloads get patched again.
  set(_espeak_stdint_shim "${CMAKE_BINARY_DIR}/_deps/espeak_ng-src/src/include/compat/stdint.h")
  if(EXISTS "${_espeak_stdint_shim}")
    file(READ "${_espeak_stdint_shim}" _espeak_shim)
    # undo any earlier form of the patch, then re-apply the conditional one,
    # so trees patched by previous versions converge to the same state
    string(REPLACE "#if defined(__clang__)\n#include_next <../include/stdint.h>\n#else\n#include <../include/stdint.h>\n#endif"
                   "#include <../include/stdint.h>" _espeak_shim "${_espeak_shim}")
    string(REPLACE "#include_next <../include/stdint.h>"
                   "#include <../include/stdint.h>" _espeak_shim "${_espeak_shim}")
    string(REPLACE "#include <../include/stdint.h>"
                   "#if defined(__clang__)\n#include_next <../include/stdint.h>\n#else\n#include <../include/stdint.h>\n#endif"
                   _espeak_shim "${_espeak_shim}")
    file(WRITE "${_espeak_stdint_shim}" "${_espeak_shim}")
    unset(_espeak_shim)
  endif()
  # simple-sentencepiece v0.7's ThreadPool deduces the task return type via
  # the function-type trick result_of<F(Args...)> (removed in C++20). A
  # hand-modernization to invoke_result<F(Args...)> misapplies it:
  # invoke_result takes the callable and its arguments as separate template
  # parameters, so with an empty Args pack F(Args...) degenerates to "function
  # returning F" and return_type becomes the lambda itself. Converge both
  # forms to the correct spelling.
  set(_ssentencepiece_threadpool "${CMAKE_BINARY_DIR}/_deps/simple-sentencepiece-src/ssentencepiece/csrc/threadpool.h")
  if(EXISTS "${_ssentencepiece_threadpool}")
    file(READ "${_ssentencepiece_threadpool}" _ssentencepiece_tp)
    string(REPLACE "std::result_of<F(Args...)>::type" "std::invoke_result_t<F, Args...>" _ssentencepiece_tp "${_ssentencepiece_tp}")
    string(REPLACE "std::invoke_result<F(Args...)>::type" "std::invoke_result_t<F, Args...>" _ssentencepiece_tp "${_ssentencepiece_tp}")
    file(WRITE "${_ssentencepiece_threadpool}" "${_ssentencepiece_tp}")
    unset(_ssentencepiece_tp)
  endif()
  unset(_ssentencepiece_threadpool)

  # /sdl escalates C4703 (potentially-uninitialized pointer, flow analysis)
  # to errors in espeak-ng's C sources; it is a false positive there and
  # sherpa upstream never builds this code with /sdl. Disable the escalation
  # for that target only; appended options come after the global ones, and
  # for cl the last /sdl on the command line wins.
  if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC" AND TARGET espeak-ng)
    target_compile_options(espeak-ng PRIVATE /sdl-)
  endif()

endfunction()
