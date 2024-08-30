set(LLAMA_VERSION      )
set(LLAMA_BUILD_COMMIT )
set(LLAMA_BUILD_NUMBER )
set(LLAMA_SHARED_LIB   ON)

set(GGML_BLAS       ON)
set(GGML_CUDA       OFF)
set(GGML_METAL      ON)
set(GGML_HIPBLAS    OFF)
set(GGML_ACCELERATE ON)


####### Expanded from @PACKAGE_INIT@ by configure_package_config_file() #######
####### Any changes to this file will be overwritten by the next CMake run ####
####### The input file was llama-config.cmake.in                            ########

get_filename_component(PACKAGE_PREFIX_DIR "${CMAKE_CURRENT_LIST_DIR}/../../../" ABSOLUTE)

macro(set_and_check _var _file)
  set(${_var} "${_file}")
  if(NOT EXISTS "${_file}")
    message(FATAL_ERROR "File or directory ${_file} referenced by variable ${_var} does not exist !")
  endif()
endmacro()

macro(check_required_components _NAME)
  foreach(comp ${${_NAME}_FIND_COMPONENTS})
    if(NOT ${_NAME}_${comp}_FOUND)
      if(${_NAME}_FIND_REQUIRED_${comp})
        set(${_NAME}_FOUND FALSE)
      endif()
    endif()
  endforeach()
endmacro()

####################################################################################

set_and_check(LLAMA_INCLUDE_DIR "")
set_and_check(LLAMA_LIB_DIR     "")
set_and_check(LLAMA_BIN_DIR     "")

# Ensure transient dependencies satisfied

find_package(Threads REQUIRED)

if (APPLE AND GGML_ACCELERATE)
    find_library(ACCELERATE_FRAMEWORK Accelerate REQUIRED)
endif()

if (GGML_BLAS)
    find_package(BLAS REQUIRED)
endif()

if (GGML_CUDA)
    find_package(CUDAToolkit REQUIRED)
endif()

if (GGML_METAL)
    find_library(FOUNDATION_LIBRARY Foundation REQUIRED)
    find_library(METAL_FRAMEWORK Metal REQUIRED)
    find_library(METALKIT_FRAMEWORK MetalKit REQUIRED)
endif()

if (GGML_HIPBLAS)
    find_package(hip REQUIRED)
    find_package(hipblas REQUIRED)
    find_package(rocblas REQUIRED)
endif()

find_library(llama_LIBRARY llama
    REQUIRED
    HINTS ${LLAMA_LIB_DIR})

set(_llama_link_deps "Threads::Threads" "")
set(_llama_transient_defines "")

add_library(llama UNKNOWN IMPORTED)

set_target_properties(llama
    PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${LLAMA_INCLUDE_DIR}"
        INTERFACE_LINK_LIBRARIES "${_llama_link_deps}"
        INTERFACE_COMPILE_DEFINITIONS "${_llama_transient_defines}"
        IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
        IMPORTED_LOCATION "${llama_LIBRARY}"
        INTERFACE_COMPILE_FEATURES cxx_std_11
        POSITION_INDEPENDENT_CODE ON )

check_required_components(Llama)
