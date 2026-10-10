# OWNER: AI-03
#
# Native build of the vwish whisper shim (ai.md §4.6, ARCH §16.1).
#
#  * Host build (macOS / Linux, CPU only): the shim + the vendored whisper.cpp/ggml as static libraries
#    and the host test runner `vw_tests` (CTest). Used by scripts/ci/editor/whisper_host.sh.
#  * Android (Gradle externalNativeBuild points here): everything platform specific lives in AI-04's
#    cmake/android.cmake, included below. It reuses VW_SHIM_SOURCES / VW_SHIM_INCLUDE_DIR /
#    VW_WHISPER_SOURCE_DIR and links the Android `log` library (vw_log.cpp uses __android_log_print).
#  * iOS: AI-05's tool/build_ios_xcframework.sh builds whisper/ggml; ios/Classes/vw_whisper_forwarder.cpp
#    #includes the shim sources (all vw_*.cpp compile as one translation unit; tests/vw_unity_check.cpp
#    guards that).
#
# Host options:
#   -DVW_SANITIZER=none|thread|address   sanitizer for the shim, the tests and whisper/ggml
#   -DVW_BUILD_TESTS=ON|OFF               build tests/ (default ON for host builds)
cmake_minimum_required(VERSION 3.14)

project(vwish_whisper_shim C CXX)

set(VW_SHIM_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}")
set(VW_WHISPER_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/../third_party/whisper.cpp")
get_filename_component(VW_WHISPER_SOURCE_DIR "${VW_WHISPER_SOURCE_DIR}" ABSOLUTE)

# The shim. Every file is also compiled as part of one translation unit on iOS (forwarder), so file-local
# helpers use distinct names (see tests/vw_unity_check.cpp).
set(VW_SHIM_SOURCES
  "${CMAKE_CURRENT_LIST_DIR}/vw_whisper.cpp"
  "${CMAKE_CURRENT_LIST_DIR}/vw_log.cpp"
  "${CMAKE_CURRENT_LIST_DIR}/vw_cpu.cpp"
  "${CMAKE_CURRENT_LIST_DIR}/vw_wav.cpp"
  "${CMAKE_CURRENT_LIST_DIR}/vw_chunker.cpp"
  "${CMAKE_CURRENT_LIST_DIR}/vw_words.cpp"
  "${CMAKE_CURRENT_LIST_DIR}/vw_json.cpp"
  "${CMAKE_CURRENT_LIST_DIR}/vw_vad.cpp"
  "${CMAKE_CURRENT_LIST_DIR}/vw_registry.cpp"
  "${CMAKE_CURRENT_LIST_DIR}/vw_model.cpp"
  "${CMAKE_CURRENT_LIST_DIR}/vw_job.cpp"
)

if(ANDROID OR VW_ANDROID)
  if(NOT EXISTS "${CMAKE_CURRENT_LIST_DIR}/cmake/android.cmake")
    message(FATAL_ERROR "src/cmake/android.cmake is missing (owned by AI-04, the whisper Android native build).")
  endif()
  include("${CMAKE_CURRENT_LIST_DIR}/cmake/android.cmake")
  return()
endif()

# ---------------------------------------------------------------------------------------------------
# Host build (CPU only)
# ---------------------------------------------------------------------------------------------------

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "Build type" FORCE)
endif()

set(VW_SANITIZER "none" CACHE STRING "Sanitizer for host tests: none, thread or address")
set_property(CACHE VW_SANITIZER PROPERTY STRINGS none thread address)
option(VW_BUILD_TESTS "Build the vwish whisper host tests" ON)

# whisper.cpp / ggml: static, CPU backend only, same switches as the device builds (ai.md §4.3/§4.4)
# minus the platform ones. Metal/BLAS/Accelerate are off so macOS hosts test the CPU path.
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_IS_DEV OFF CACHE BOOL "" FORCE)   # v1.9.4 is a release tag: whisper_version() == "1.9.4"
set(WHISPER_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_SERVER OFF CACHE BOOL "" FORCE)
set(WHISPER_CURL OFF CACHE BOOL "" FORCE)
set(WHISPER_SDL2 OFF CACHE BOOL "" FORCE)
set(WHISPER_COREML OFF CACHE BOOL "" FORCE)
set(WHISPER_OPENVINO OFF CACHE BOOL "" FORCE)
set(WHISPER_ALL_WARNINGS OFF CACHE BOOL "" FORCE)
set(GGML_NATIVE OFF CACHE BOOL "" FORCE)
set(GGML_OPENMP OFF CACHE BOOL "" FORCE)
set(GGML_CPU_KLEIDIAI OFF CACHE BOOL "" FORCE)
set(GGML_BACKEND_DL OFF CACHE BOOL "" FORCE)
set(GGML_METAL OFF CACHE BOOL "" FORCE)
set(GGML_BLAS OFF CACHE BOOL "" FORCE)
set(GGML_ACCELERATE OFF CACHE BOOL "" FORCE)
set(GGML_CCACHE OFF CACHE BOOL "" FORCE)

set(VW_SAN_FLAGS "")
if(VW_SANITIZER STREQUAL "thread")
  set(WHISPER_SANITIZE_THREAD ON CACHE BOOL "" FORCE)
  set(VW_SAN_FLAGS -fsanitize=thread -fno-omit-frame-pointer)
elseif(VW_SANITIZER STREQUAL "address")
  set(WHISPER_SANITIZE_ADDRESS ON CACHE BOOL "" FORCE)
  set(VW_SAN_FLAGS -fsanitize=address -fno-omit-frame-pointer)
elseif(NOT VW_SANITIZER STREQUAL "none")
  message(FATAL_ERROR "VW_SANITIZER must be none, thread or address (got '${VW_SANITIZER}')")
endif()

add_subdirectory("${VW_WHISPER_SOURCE_DIR}" whisper_cpp EXCLUDE_FROM_ALL)

find_package(Threads REQUIRED)

add_library(vw_shim STATIC ${VW_SHIM_SOURCES})
target_include_directories(vw_shim PUBLIC "${VW_SHIM_INCLUDE_DIR}")
target_link_libraries(vw_shim PUBLIC whisper Threads::Threads)
target_compile_options(vw_shim PRIVATE -Wall -Wextra -Werror=format -Wno-unused-parameter ${VW_SAN_FLAGS})
target_link_options(vw_shim PUBLIC ${VW_SAN_FLAGS})
# Host builds log to stderr (iOS uses os_log and Android logcat; see vw_log.cpp).
target_compile_definitions(vw_shim PRIVATE VW_HOST_BUILD=1)

if(VW_BUILD_TESTS)
  enable_testing()
  add_subdirectory(tests)
endif()
