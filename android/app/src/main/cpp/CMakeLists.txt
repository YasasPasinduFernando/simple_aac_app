cmake_minimum_required(VERSION 3.22.1)
project(aac_voice_dsp LANGUAGES CXX)

add_library(aac_voice_dsp SHARED
    aac_voice_dsp.cpp
)

target_include_directories(aac_voice_dsp PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)

target_compile_options(aac_voice_dsp PRIVATE
    -std=c++17
    -O3
    -ffast-math
    -fvisibility=hidden
)

# Enforce 16 KB ELF LOAD alignment for Android 15+ / Google Play compliance.
target_link_options(aac_voice_dsp PRIVATE
    -Wl,-z,max-page-size=16384
)

find_library(log-lib log)
target_link_libraries(aac_voice_dsp ${log-lib})
