# GAP

[![ci](https://github.com/NiNeDelixe/GAP/actions/workflows/ci.yml/badge.svg)](https://github.com/NiNeDelixe/GAP/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/NiNeDelixe/GAP/branch/main/graph/badge.svg)](https://codecov.io/gh/NiNeDelixe/GAP)
[![CodeQL](https://github.com/NiNeDelixe/GAP/actions/workflows/codeql-analysis.yml/badge.svg)](https://github.com/NiNeDelixe/GAP/actions/workflows/codeql-analysis.yml)

## About GAP

## Text-to-speech

`GAP::GAP` exposes [Sherpa-ONNX](https://github.com/k2-fsa/sherpa-onnx)
v1.13.8's C++ TTS API. Voice models are external assets, so applications can
ship only the languages and voices they need.

```cmake
target_link_libraries(my_game PRIVATE GAP::GAP)
```

```cpp
#include <sherpa-onnx/c-api/cxx-api.h>

sherpa_onnx::cxx::OfflineTtsConfig config;
config.model.vits.model = "voice/model.onnx";
config.model.vits.tokens = "voice/tokens.txt";
config.model.vits.data_dir = "voice/espeak-ng-data";

auto tts = sherpa_onnx::cxx::OfflineTts::Create(config);
auto audio = tts.Generate("Hello, world!");
```

Use a model package whose `tokens.txt` contains its phoneme set. Its
`espeak-ng-data` directory supplies language rules and custom phonemes; the
voice metadata selects the eSpeak language. For models that use a lexicon
frontend instead, set `config.model.vits.lexicon` and leave `data_dir` empty.
Sherpa-ONNX ignores `lexicon` when `data_dir` is set.


## WebAssembly Demo

Try the live WebAssembly demo:
- Main: [https://NiNeDelixe.github.io/GAP/](https://NiNeDelixe.github.io/GAP/)
- Develop: [https://NiNeDelixe.github.io/GAP/develop/](https://NiNeDelixe.github.io/GAP/develop/)

The `main` branch deploys to the root, `develop` to `/develop/`, and tags to `/tagname/`.


## More Details

 * [Dependency Setup](README_dependencies.md)
 * [Building Details](README_building.md)
 * [Troubleshooting](README_troubleshooting.md)
 * [Docker](README_docker.md)
