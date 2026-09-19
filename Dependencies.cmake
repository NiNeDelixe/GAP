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

  if(NOT TARGET piper)
    # Piper provides and tests the compatible ONNX Runtime binary itself. A
    # second source build of ORT can put an older DLL on the runtime search
    # path, which is incompatible with current Piper voice models.
    cpmaddpackage(
      NAME piper
      GIT_TAG 639388b6317fc4731e91d53da42aea68fd4166ff # v1.8.0
      GITHUB_REPOSITORY "OHF-Voice/piper1-gpl"
      SYSTEM YES
      SOURCE_SUBDIR libpiper
      #PATCHES "${CMAKE_CURRENT_SOURCE_DIR}/patches/piper-cmake-source-dir.patch"
      OPTIONS "PIPER_BUILD_TESTS OFF")

    # libpiper uses CMAKE_BINARY_DIR for this location when embedded with CPM.
    # Keep it on the target so consumers can stage the required phoneme data.
    set_property(
      TARGET piper
      PROPERTY GAP_PIPER_ESPEAK_DATA_DIR
               "${CMAKE_BINARY_DIR}/espeak_ng-install/share/espeak-ng-data")
  endif()

  if(NOT TARGET GAP_piper)
    add_library(GAP_piper INTERFACE)
    target_link_libraries(GAP_piper INTERFACE piper)
    add_library(GAP::Piper ALIAS GAP_piper)
  endif()

endfunction()

# Copy Piper's shared libraries and phonemizer data to a runnable consumer.
# This is intentionally opt-in: library-only users do not need to ship them.
function(GAP_stage_piper_runtime target)
  cmake_parse_arguments(GAP_PIPER_STAGE "" "DATA_DESTINATION" "" ${ARGN})

  if(NOT TARGET "${target}")
    message(FATAL_ERROR "GAP_stage_piper_runtime: target '${target}' does not exist")
  endif()

  # if(NOT TARGET piper OR NOT TARGET onnxruntime)
  #   message(FATAL_ERROR "GAP_stage_piper_runtime: GAP::Piper is not available")
  # endif()

  get_property(
    piper_espeak_data_dir
    TARGET piper
    PROPERTY GAP_PIPER_ESPEAK_DATA_DIR)
  if(NOT piper_espeak_data_dir)
    message(FATAL_ERROR
            "GAP_stage_piper_runtime: Piper was provided externally without its espeak-ng data directory")
  endif()

  if(NOT GAP_PIPER_STAGE_DATA_DESTINATION)
    set(GAP_PIPER_STAGE_DATA_DESTINATION "resources/voice/models/espeak-ng-data")
  endif()

  add_custom_command(
    TARGET "${target}"
    POST_BUILD
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different "$<TARGET_FILE:piper>"
            "$<TARGET_FILE_DIR:${target}>"
    # Piper's imported ONNX Runtime target points to its import library on
    # Windows. Copying that directory preserves the corresponding DLL and
    # provider libraries on every supported platform.
    COMMAND "${CMAKE_COMMAND}" -E copy_directory
            "$<TARGET_FILE_DIR:onnxruntime::onnxruntime>" "$<TARGET_FILE_DIR:${target}>"
    COMMAND "${CMAKE_COMMAND}" -E copy_directory "${piper_espeak_data_dir}"
            "$<TARGET_FILE_DIR:${target}>/${GAP_PIPER_STAGE_DATA_DESTINATION}")
endfunction()
