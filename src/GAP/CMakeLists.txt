include(GenerateExportHeader)


add_library(GAP GAP.cpp)



add_library(GAP::GAP ALIAS GAP)

# if(WIN32)
#     set_target_properties(onnxruntime PROPERTIES
#         IMPORTED_LOCATION ${piper_BINARY_DIR}/onnxruntime.dll
#         IMPORTED_IMPLIB   ${piper_BINARY_DIR}/onnxruntime.lib
#     )
# elseif(UNIX AND NOT APPLE)
#     set_target_properties(onnxruntime PROPERTIES
#         IMPORTED_LOCATION ${piper_BINARY_DIR}/libonnxruntime.so
#     )
# elseif(APPLE)
#     set_target_properties(onnxruntime PROPERTIES
#         IMPORTED_LOCATION ${piper_BINARY_DIR}/libonnxruntime.dylib
#     )
# endif()

target_link_libraries(GAP PRIVATE 
  GAP_options 
  GAP_warnings
  piper
  #onnxruntime::onnxruntime
  onnxruntime
  FlatBuffers
)

# add_custom_command(TARGET GAP POST_BUILD
#     COMMAND ${CMAKE_COMMAND} -E copy_if_different
#         "$<TARGET_FILE:piper>"
#         "$<TARGET_FILE_DIR:GAP>/"
# )

target_include_directories(GAP ${WARNING_GUARD} PUBLIC $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/src>
                                                                  #$<BUILD_INTERFACE:${PROJECT_BINARY_DIR}/src>
                                                                  )

if (GAP_BUILD_FUZZ_TESTS)
  target_link_libraries(GAP PRIVATE -fsanitize=fuzzer-no-link)
  target_compile_options(GAP PRIVATE -fsanitize=fuzzer-no-link)
endif()

target_compile_features(GAP PUBLIC cxx_std_${CMAKE_CXX_STANDARD})

GAP_configure_linker(GAP)

set_target_properties(
  GAP
  PROPERTIES VERSION ${PROJECT_VERSION}
             CXX_VISIBILITY_PRESET hidden
             VISIBILITY_INLINES_HIDDEN YES)

generate_export_header(GAP EXPORT_FILE_NAME ${PROJECT_BINARY_DIR}/include/GAP/GAP_export.hpp)

if(NOT BUILD_SHARED_LIBS)
  target_compile_definitions(GAP PUBLIC GAP_STATIC_DEFINE)
endif()
