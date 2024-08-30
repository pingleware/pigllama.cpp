cmake_minimum_required(VERSION 3.14) # for add_link_options and implicit target directories.
project("pigllama.cpp" C CXX)
include(CheckIncludeFileCXX)

#set(CMAKE_WARN_DEPRECATED YES)
set(CMAKE_WARN_UNUSED_CLI YES)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if (NOT XCODE AND NOT MSVC AND NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

# Add path to modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/")

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

if (CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    set(PIGLLAMA_STANDALONE ON)

    include(git-vars)

    # configure project version
    # TODO
else()
    set(PIGLLAMA_STANDALONE OFF)
endif()

if (EMSCRIPTEN)
    set(BUILD_SHARED_LIBS_DEFAULT OFF)

    option(PIGLLAMA_WASM_SINGLE_FILE "pigllama: embed WASM inside the generated llama.js" ON)
else()
    if (MINGW)
        set(BUILD_SHARED_LIBS_DEFAULT OFF)
    else()
        set(BUILD_SHARED_LIBS_DEFAULT ON)
    endif()
endif()

option(BUILD_SHARED_LIBS "build shared libraries" ${BUILD_SHARED_LIBS_DEFAULT})

if (WIN32)
    add_compile_definitions(_CRT_SECURE_NO_WARNINGS)
endif()

#
# option list
#

# general
option(PIGLLAMA_CCACHE "pigllama: use ccache if available" ON)

# debug
option(PIGLLAMA_ALL_WARNINGS           "pigllama: enable all compiler warnings"                   ON)
option(PIGLLAMA_ALL_WARNINGS_3RD_PARTY "pigllama: enable all compiler warnings in 3rd party libs" OFF)

# build
option(PIGLLAMA_FATAL_WARNINGS "pigllama: enable -Werror flag" OFF)

# sanitizers
option(PIGLLAMA_SANITIZE_THREAD    "pigllama: enable thread sanitizer"    OFF)
option(PIGLLAMA_SANITIZE_ADDRESS   "pigllama: enable address sanitizer"   OFF)
option(PIGLLAMA_SANITIZE_UNDEFINED "pigllama: enable undefined sanitizer" OFF)

# extra artifacts
option(PIGLLAMA_BUILD_TESTS    "pigllama: build tests"          ${PIGLLAMA_STANDALONE})
option(PIGLLAMA_BUILD_EXAMPLES "pigllama: build examples"       ${PIGLLAMA_STANDALONE})
option(PIGLLAMA_BUILD_SERVER   "pigllama: build server example" ${PIGLLAMA_STANDALONE})

# 3rd party libs
option(PIGLLAMA_CURL "pigllama: use libcurl to download model from an URL" OFF)

# Required for relocatable CMake package
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/build-info.cmake)

# override ggml options
set(GGML_CCACHE             ${PIGLLAMA_CCACHE})
set(GGML_SANITIZE_THREAD    ${PIGLLAMA_SANITIZE_THREAD})
set(GGML_SANITIZE_ADDRESS   ${PIGLLAMA_SANITIZE_ADDRESS})
set(GGML_SANITIZE_UNDEFINED ${PIGLLAMA_SANITIZE_UNDEFINED})
set(GGML_ALL_WARNINGS       ${PIGLLAMA_ALL_WARNINGS})
set(GGML_FATAL_WARNINGS     ${PIGLLAMA_FATAL_WARNINGS})

# change the default for these ggml options
if (NOT DEFINED GGML_LLAMAFILE)
    set(GGML_LLAMAFILE ON)
endif()

if (NOT DEFINED GGML_CUDA_USE_GRAPHS)
    set(GGML_CUDA_USE_GRAPHS ON)
endif()

# transition helpers
function (PIGLLAMA_option_depr TYPE OLD NEW)
    if (${OLD})
        message(${TYPE} "${OLD} is deprecated and will be removed in the future.\nUse ${NEW} instead\n")
        set(${NEW} ON PARENT_SCOPE)
    endif()
endfunction()

pigllama_option_depr(FATAL_ERROR PIGLLAMA_CUBLAS              GGML_CUDA)
pigllama_option_depr(WARNING     PIGLLAMA_CUDA                GGML_CUDA)
pigllama_option_depr(WARNING     PIGLLAMA_KOMPUTE             GGML_KOMPUTE)
pigllama_option_depr(WARNING     PIGLLAMA_METAL               GGML_METAL)
pigllama_option_depr(WARNING     PIGLLAMA_METAL_EMBED_LIBRARY GGML_METAL_EMBED_LIBRARY)
pigllama_option_depr(WARNING     PIGLLAMA_NATIVE              GGML_NATIVE)
pigllama_option_depr(WARNING     PIGLLAMA_RPC                 GGML_RPC)
pigllama_option_depr(WARNING     PIGLLAMA_SYCL                GGML_SYCL)
pigllama_option_depr(WARNING     PIGLLAMA_SYCL_F16            GGML_SYCL_F16)

#
# build the library
#

add_subdirectory(ggml)
add_subdirectory(src)

#
# install
#

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

set(PIGLLAMA_BUILD_NUMBER        ${BUILD_NUMBER})
set(PIGLLAMA_BUILD_COMMIT        ${BUILD_COMMIT})
set(PIGLLAMA_INSTALL_VERSION 0.0.${BUILD_NUMBER})

set(PIGLLAMA_INCLUDE_INSTALL_DIR ${CMAKE_INSTALL_INCLUDEDIR} CACHE PATH "Location of header  files")
set(PIGLLAMA_LIB_INSTALL_DIR     ${CMAKE_INSTALL_LIBDIR}     CACHE PATH "Location of library files")
set(PIGLLAMA_BIN_INSTALL_DIR     ${CMAKE_INSTALL_BINDIR}     CACHE PATH "Location of binary  files")

get_directory_property(PIGLLAMA_TRANSIENT_DEFINES COMPILE_DEFINITIONS)

set_target_properties(PIGLLAMA PROPERTIES PUBLIC_HEADER ${CMAKE_CURRENT_SOURCE_DIR}/include/pigllama.h)
install(TARGETS pigllama LIBRARY PUBLIC_HEADER)

configure_package_config_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/cmake/llama-config.cmake.in
        ${CMAKE_CURRENT_BINARY_DIR}/llama-config.cmake
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/llama
    PATH_VARS PIGLLAMA_INCLUDE_INSTALL_DIR
              PIGLLAMA_LIB_INSTALL_DIR
              PIGLLAMA_BIN_INSTALL_DIR )

write_basic_package_version_file(
        ${CMAKE_CURRENT_BINARY_DIR}/llama-version.cmake
    VERSION ${PIGLLAMA_INSTALL_VERSION}
    COMPATIBILITY SameMajorVersion)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/llama-config.cmake
              ${CMAKE_CURRENT_BINARY_DIR}/llama-version.cmake
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/llama)

install(
    FILES convert_hf_to_gguf.py
    PERMISSIONS
        OWNER_READ
        OWNER_WRITE
        OWNER_EXECUTE
        GROUP_READ
        GROUP_EXECUTE
        WORLD_READ
        WORLD_EXECUTE
    DESTINATION ${CMAKE_INSTALL_BINDIR})

configure_file(cmake/llama.pc.in
        "${CMAKE_CURRENT_BINARY_DIR}/llama.pc"
        @ONLY)

install(FILES "${CMAKE_CURRENT_BINARY_DIR}/llama.pc"
        DESTINATION lib/pkgconfig)

#
# programs, examples and tests
#

add_subdirectory(common)

if (PIGLLAMA_BUILD_TESTS AND NOT CMAKE_JS_VERSION)
    include(CTest)
    add_subdirectory(tests)
endif ()

if (PIGLLAMA_BUILD_EXAMPLES)
    add_subdirectory(examples)
    add_subdirectory(pocs)
endif()
