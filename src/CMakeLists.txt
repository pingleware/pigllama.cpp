# TODO: should not use this
if (WIN32)
    if (BUILD_SHARED_LIBS)
        set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)
    endif()
endif()

#
# libraries
#

# llama

add_library(pigllama
            ../include/pigllama.h
            pigllama.cpp
            unicode.h
            unicode.cpp
            unicode-data.cpp
            )

target_include_directories(pigllama PUBLIC . ../include)
target_compile_features   (pigllama PUBLIC cxx_std_11) # don't bump

target_link_libraries(pigllama PUBLIC ggml)

if (BUILD_SHARED_LIBS)
    set_target_properties(pigllama PROPERTIES POSITION_INDEPENDENT_CODE ON)
    target_compile_definitions(pigllama PRIVATE PIGLLAMA_SHARED PIGLLAMA_BUILD)
endif()
