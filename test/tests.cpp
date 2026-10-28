#include <catch2/catch_test_macros.hpp>
#include <sherpa-onnx/c-api/cxx-api.h>


// #include <GAP/sample_library.hpp>


TEST_CASE("Factorials are computed", "[factorial]")
{
  // REQUIRE(factorial(0) == 1);
  // REQUIRE(factorial(1) == 1);
  // REQUIRE(factorial(2) == 2);
  // REQUIRE(factorial(3) == 6);
  // REQUIRE(factorial(10) == 3628800);
}

TEST_CASE("TTS C++ API is available", "[tts]")
{
  sherpa_onnx::cxx::OfflineTtsConfig config;
  REQUIRE(config.model.vits.model.empty());
}
