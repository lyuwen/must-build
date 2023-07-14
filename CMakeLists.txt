cmake_minimum_required(VERSION 3.2)
project(MuST LANGUAGES C Fortran)

# Custome cmake utils
list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)

include(FortranCInterface)
FortranCInterface_VERIFY()

#
OPTION(WITH_NVHPC "Build with NVHPC Compilers" OFF)
OPTION(WITH_P3D "Build with P3DFFT" OFF)
OPTION(ENABLE_GPU "Build with GPU support" OFF)
# OPTION(ENABLE_GPU ON)
OPTION(WITH_OPENMP "Build with OpenMP" OFF)
OPTION(SOURCE_DIR "The directory of the source files." OFF)
OPTION(WITH_DEBUG_UTILS "Build with debug utilities." OFF)

# SW Arch
OPTION(WITH_SW "Build for SW architecture" OFF)
OPTION(WITH_SWMATQUE "SW-Matrix-Queue library is needed to build for SW architecture")

# Basic checks
if (WITH_SW)
  set(WITH_NVHPC OFF)
  set(ENABLE_GPU OFF)
  set(WITH_OPENMP OFF)
  if (NOT DEFINED WITH_SWMATQUE)
    MESSAGE(FATAL_ERROR "SW-Matrix-Queue library is needed to build for SW architecture!")
  endif()
endif ()


if (ENABLE_GPU)
  cmake_policy(SET CMP0104 OLD)
    include(CheckLanguage)
    message(STATUS "CUDA is activated: " ${ENABLE_GPU})
    check_language(CUDA)
    if (CMAKE_CUDA_COMPILER)
        enable_language(CUDA)
    else ()
        message(FATAL_ERROR "No CUDA compiler found")
    endif ()
    enable_language(CXX)
    FortranCInterface_VERIFY(CXX)
endif ()

#
# Compiler flags
#
# set(CMAKE_CXX_FLAGS "-Wall -Wextra")
include(CheckFortranCompilerFlag)
check_fortran_compiler_flag("-heap-arrays" SUPPORT_HEAPARRAYS)
if (SUPPORT_HEAPARRAYS)
  set(CMAKE_Fortran_FLAGS "-heap-arrays")
endif ()
check_fortran_compiler_flag("-ffree-line-length-none" SUPPORT_FREELINELENGTH)
if (SUPPORT_FREELINELENGTH)
  set(CMAKE_Fortran_FLAGS "-ffree-line-length-none")
endif ()
set(CMAKE_Fortran_FLAGS_DEBUG "-g")
set(CMAKE_Fortran_FLAGS_RELEASE "-O3")

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

cmake_policy(SET CMP0074 NEW)

#
# Software version
#
find_package(Git REQUIRED)
execute_process(COMMAND ${GIT_EXECUTABLE} tag | sort -V | tail -n 1 OUTPUT_VARIABLE MUST_GIT_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
if ("${MUST_GIT_VERSION}" STREQUAL "")
  execute_process(COMMAND ${GIT_EXECUTABLE} branch --show-current OUTPUT_VARIABLE MUST_GIT_BRANCH OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
  if ("${MUST_GIT_BRANCH}" STREQUAL "")
    set(MUST_GIT_VERSION "Develop")
  else()
    set(MUST_GIT_VERSION "Develop, Git Branch: ${MUST_GIT_BRANCH}")
  endif()
else()
  execute_process(COMMAND ${GIT_EXECUTABLE} tag | sort -V | tail -n 1 | sed 's/^/\"/' | sed 's/$$/\"/' OUTPUT_VARIABLE MUST_GIT_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
endif()
message(STATUS "MuST Git VERSION: ${MUST_GIT_VERSION}")
message(STATUS "Generate file ${CMAKE_BINARY_DIR}/src/get_virsion.h from template.")
configure_file(${PROJECT_SOURCE_DIR}/cmake/git_version.h.in ${CMAKE_BINARY_DIR}/src/git_version.h)
#
set(USER $ENV{USER})
set(HOSTNAME $ENV{HOSTNAME})
string(TIMESTAMP COMPILEDATE "%A, %B %d %Y %H:%M:%S")
message(STATUS "Compiled by ${USER}, at node ${HOSTNAME}, on ${COMPILEDATE}.")
configure_file(${PROJECT_SOURCE_DIR}/cmake/print_version_include.h.in ${CMAKE_BINARY_DIR}/src/print_version_include.h)
include_directories("${CMAKE_BINARY_DIR}/src")
##########

#
# External dependencies
# set(BLA_STATIC ON)
#
find_package(MPI REQUIRED)
include_directories(${MPI_INCLUDE_PATH})
# find_package(rpclib REQUIRED)
if (WITH_SW)
  find_package(SWMATH REQUIRED swblas swlapack swscalapack)
else ()
  find_package(BLAS REQUIRED)
  find_package(LAPACK REQUIRED)
  find_package(SCALAPACK REQUIRED)
endif()
if (WITH_P3D)
  find_package(P3DFFT REQUIRED)
endif()
find_package(LibXC REQUIRED Fortran)
set(FFTW_USE_STATIC ON)
find_package(FFTW REQUIRED MPI)
set(HDF5_USE_STATIC_LIBRARIES ON)
find_package(HDF5 COMPONENTS Fortran)
if (NOT HDF5_FOUND)
  add_compile_definitions(NOHDF5)
endif()
#
find_package(RPC REQUIRED)

OPTION(BUILD_SHARED_LIBS "Build shared libraries" OFF )
OPTION(BUILD_STATIC_LIBS "Build static libraries" ON )

# --------------------------------------------------
# Subdirectories that need to be processed

if(NOT SOURCE_DIR)
  set(SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
endif()
message(STATUS "SOURCE_DIR=${SOURCE_DIR}")

macro(append_subdir_files variable dirname)
get_directory_property(holder DIRECTORY ${dirname} DEFINITION ${variable})
foreach(depfile ${holder})
  list(APPEND ${variable} "${SOURCE_DIR}/${dirname}/${depfile}")
endforeach()
endmacro()

#
# SRC
#
add_subdirectory(lib)
append_subdir_files(LIB_MODULES "lib")
append_subdir_files(LIB_LOBS "lib")
if (WITH_DEBUG_UTILS)
  append_subdir_files(LDEBUG_LOBS "lib")
endif()

message(STATUS "LIB_LOBS = ${LIB_LOBS}")

add_subdirectory(iolib)
append_subdir_files(IO_OBJS "iolib")

add_subdirectory(plib)
append_subdir_files(MPP_MODULES "plib")

add_subdirectory(src)
append_subdir_files(BasicModules "src")
append_subdir_files(BasicRoutines "src")
append_subdir_files(AppModules "src")
append_subdir_files(HDF5Module "src")
append_subdir_files(Modules_2 "src")
append_subdir_files(Routines "src")

if (ENABLE_GPU)
  add_subdirectory(Accelerator)
  append_subdir_files(AccModules "Accelerator")
  add_library(MatAcc ${AccModules})
  include_directories(Accelerator)
  set_target_properties(MatAcc PROPERTIES
    CUDA_SEPARABLE_COMPILATION ON)
  target_compile_definitions(MatAcc PUBLIC CUDA)
endif()

if (WITH_SW)
  add_subdirectory("${WITH_SWMATQUE}" swmatque EXCLUDE_FROM_ALL)
  add_compile_definitions(WITH_SW)
endif ()


#
# Preprocessor flags
#
if (WITH_NVHPC)
  add_compile_definitions(NVHPC)
endif()
add_compile_definitions(LIBXC5)
add_compile_definitions(FFTW)
if (WITH_P3D)
  add_compile_definitions(P3DFFT)
endif()
add_compile_definitions(MPI)
add_compile_definitions(Underscore)
add_compile_definitions(USE_SCALAPACK)
add_compile_definitions(MaxOutProcs=1)
add_compile_definitions(LSMS2)

#
# Libraries
#
if (WITH_DEBUG_UTILS)
  add_library(mst ${LIB_MODULES} ${LIB_LOBS} ${LDEBUG_LOBS})
else()
  add_library(mst ${LIB_MODULES} ${LIB_LOBS})
endif()

add_library(iolib ${IO_OBJS})
include_directories(iolib)

add_library(plib ${MPP_MODULES})
add_dependencies(plib mst)

#
# Programs
# MST2
if (HDF5_FOUND)
  add_executable(mst2 ${SOURCE_DIR}/src/mst2.F90 ${BasicModules} ${BasicRoutines} ${AppModules} ${HDF5Module} ${Modules_2} ${Routines})
else()
  add_executable(mst2 ${SOURCE_DIR}/src/mst2.F90 ${BasicModules} ${BasicRoutines} ${AppModules} ${Modules_2} ${Routines})
endif()

target_link_libraries(mst2 PRIVATE mst)
target_link_libraries(mst2 PRIVATE iolib)
target_link_libraries(mst2 PRIVATE plib)

if (WITH_SW)
  target_link_libraries(mst2 PRIVATE swmatque)
endif ()

# Find OpenMP library
# if (WITH_OPENMP)
#     find_package(OpenMP REQUIRED)
#     target_link_libraries(mst2 PUBLIC OpenMP::OpenMP_Fortran)
# endif ()
# CUDA
if (ENABLE_GPU)
    target_link_libraries(mst2 PRIVATE MatAcc)

    add_compile_definitions(ACCELERATOR_CUDA_C)
    add_compile_definitions(ACCEL)
    add_compile_definitions(ACCEL_CXX)

    option(CUDA_DEBUG "Debug CUDA routines" OFF)

    if (CUDA_DEBUG)
        target_compile_definitions(mst2 PUBLIC "CUDA_DEBUG")
    endif ()


    # Build with OpenMP
    if (WITH_OPENMP)
        add_compile_definitions(_OPENMP)
        message(STATUS "OpenMP is also defined for GPU")
        target_compile_options(MatAcc PUBLIC $<$<COMPILE_LANGUAGE:CUDA>:-Xcompiler -fopenmp>)
    endif ()


    if (NOT DEFINED CMAKE_CUDA_STANDARD)
        set(CMAKE_CUDA_STANDARD 14)
        set(CMAKE_CUDA_STANDARD_REQUIRED ON)
    endif ()

    if (NOT DEFINED CMAKE_CUDA_SEPARABLE_COMPILATION)
        set(CMAKE_CUDA_SEPARABLE_COMPILATION OFF)
    endif ()

    find_package(CUDAToolkit REQUIRED)


    message(STATUS "CUDA Version: " ${CUDAToolkit_VERSION})
    message(STATUS "CUDA Include dirs: " ${CUDAToolkit_INCLUDE_DIRS})
    message(STATUS "CUDA Library: " ${CUDAToolkit_LIBRARY_DIR})

    target_link_libraries(mst2 PUBLIC CUDA::toolkit)

    # Check if the necessary libraries have been found
    if (TARGET CUDA::cublas)
        target_link_libraries(mst2 PUBLIC CUDA::cublas)
    else ()
        message(FATAL_ERROR "CuBLAS was not defined or found")
    endif ()

    if (TARGET CUDA::cusolver)
        target_link_libraries(mst2 PUBLIC CUDA::cusolver)
    else ()
        message(FATAL_ERROR "Cusolver was not defined or found")
    endif ()

    set_target_properties(mst2 PROPERTIES CUDA_ARCHITECTURES "60;70;80")

    add_dependencies(MatAcc mst)
endif ()


target_link_libraries(mst2 PRIVATE MPI::MPI_Fortran)
# target_link_libraries(mst2 PRIVATE "${FFTW_LIBRARIES}")
target_link_libraries(mst2 PRIVATE FFTW::fftw)
# target_link_libraries(mst2 PRIVATE "${LibXC_LIBRARIES}")
target_link_libraries(mst2 PRIVATE LibXC::libxc)
if (HDF5_FOUND)
  target_link_libraries(mst2 PRIVATE "${HDF5_Fortran_LIBRARIES}")
endif()
if (WITH_P3D)
  target_link_libraries(mst2 PRIVATE "${P3DFFT_LIBRARIES}")
endif()
target_link_libraries(mst2 PRIVATE "${RPC_LIBRARIES}")
if (WITH_SW)
  target_link_libraries(mst2 PRIVATE "${SWMATH_LIBRARIES}")
  target_link_libraries(mst2 PRIVATE "-lm_slave")
  target_link_libraries(mst2 PRIVATE "-lgfortran")
else ()
# target_link_libraries(mst2 PRIVATE BLAS::BLAS)
# target_link_libraries(mst2 PRIVATE LAPACK::LAPACK)
  target_link_libraries(mst2 PRIVATE "${BLAS_LIBRARIES}")
  target_link_libraries(mst2 PRIVATE "${LAPACK_LIBRARIES}")
  target_link_libraries(mst2 PRIVATE "${SCALAPACK_LIBRARIES}")
endif()

foreach(TGT IN ITEMS mst2 iolib plib mst)
  if (WITH_SW)
    target_include_directories(${TGT} PRIVATE "${SWMATH_INCLUDE_DIR}")
  endif()
  target_include_directories(${TGT} PRIVATE "${RPC_INCLUDE_DIR}")
  target_include_directories(${TGT} PRIVATE "${FFTW_INCLUDE_DIR}")
  target_include_directories(${TGT} PRIVATE "${LibXC_INCLUDE_DIR}")
  if (WITH_P3D)
    target_include_directories(${TGT} PRIVATE "${P3DFFT_INCLUDE_DIR}")
  endif()
  if (HDF5_FOUND)
    target_include_directories(${TGT} PRIVATE "${HDF5_Fortran_INCLUDE_DIR}")
    target_include_directories(${TGT} PRIVATE "${HDF5_Fortran_INCLUDE_DIRS}")
  endif()
endforeach()

# Utilities
add_executable(newa ${SOURCE_DIR}/util/newa.F)
add_executable(newss ${SOURCE_DIR}/util/newss.F ${SOURCE_DIR}/lib/SortModule.F90 ${SOURCE_DIR}/src/ChemElementModule.F90 ${SOURCE_DIR}/lib/KindParamModule.F90
                     ${SOURCE_DIR}/lib/ErrorHandlerModule.F90 ${SOURCE_DIR}/lib/MathParamModule.F90 ${SOURCE_DIR}/src/PhysParamModule.F90 ${SOURCE_DIR}/lib/breakLine.F90)

# Fortran modules files
include_directories(${CMAKE_BINARY_DIR}/modules)
foreach(TGT IN ITEMS mst2 iolib plib mst  newa newss)
  set_target_properties(${TGT} PROPERTIES Fortran_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/modules)
endforeach()
#
if (ENABLE_GPU)
  set_target_properties(MatAcc   PROPERTIES Fortran_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/modules)
endif()
set_property(TARGET mst2 PROPERTY LINKER_LANGUAGE Fortran)
