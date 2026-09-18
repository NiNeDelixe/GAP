include(cmake/CPM.cmake)

# Done as a function so that updates to variables like
# CMAKE_CXX_FLAGS don't propagate out to other
# targets
function(GAP_setup_dependencies)

  set(CPM_SOURCE_CACHE "${CMAKE_BINARY_DIR}/.cache/CPM")

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

  if(NOT TARGET piper)
    #set(ONNX_DISABLE_STATIC_REGISTRATION ON)
    set(CMAKE_COMPILE_WARNING_AS_ERROR OFF)

    CPMAddPackage(
      NAME onnxruntime
      GIT_TAG v1.22.2
      GITHUB_REPOSITORY microsoft/onnxruntime
      SYSTEM YES
      SOURCE_SUBDIR cmake
      OPTIONS
      "onnxruntime_BUILD_UNIT_TESTS OFF"
      "onnxruntime_ENABLE_PYTHON OFF"
      "onnxruntime_USE_VCPKG ON"
      "onnxruntime_DISABLE_ABSEIL ON"
      "onnxruntime_USE_PREINSTALLED_EIGEN ON"
      "onnxruntime_PREFER_SYSTEM_LIB OFF"
    )
    
    foreach(target
    onnxruntime
    onnxruntime_framework
    onnxruntime_common
)
    if(TARGET ${target})
        target_compile_options(${target} PRIVATE /WX-)
    endif() 
    endforeach()

    if(TARGET onnxruntime_framework)
    target_compile_options(onnxruntime_framework PRIVATE /wd4875)
endif()

    cpmaddpackage(
      NAME piper
      GIT_TAG "main"
      GITHUB_REPOSITORY OHF-Voice/piper1-gpl
      SYSTEM YES
      SOURCE_SUBDIR libpiper 
      PATCHES "${CMAKE_CURRENT_SOURCE_DIR}\\patches\\piper-cmake-source-dir.patch"
      OPTIONS
      "PIPER_BUILD_SEPARATE_LIBS ON" 
      #"ONNX_DISABLE_STATIC_REGISTRATION=ON"
      )

  endif()

endfunction()
