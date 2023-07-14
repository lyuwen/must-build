#  Copyright Olivier Parcollet 2010.
#  Copyright Simons Foundation 2019
#    Author: Nils Wentzell
#  Copyright Lyuwen Fu 2022

#  Distributed under the Boost Software License, Version 1.0.
#      (See accompanying file LICENSE_1_0.txt or copy at
#          http://www.boost.org/LICENSE_1_0.txt)

#
# This module looks for fftw.
# It sets up : FFTW_INCLUDE_DIR, FFTW_LIBRARIES
# Use FFTW3_ROOT to specify a particular location
#

if(FFTW_INCLUDE_DIR AND FFTW_LIBRARIES)
  set(FFTW_FIND_QUIETLY TRUE)
endif()

set(FFTW_INCLUDE_DIR)
set(FFTW_LIBRARIES)
set(FFTW_FOUND FALSE)
set(FFTW_BUILD_FROM_SOURCE FALSE)
foreach(PART IN ITEMS MPI OMP Threads)
  set(FFTW_${PART}_FOUND FALSE)
endforeach()

find_path(FFTW_INCLUDE_DIR
  NAMES fftw3.h
  HINTS
    ${FFTW3_ROOT}/include
    ${FFTW_ROOT}/include
    $ENV{MKLROOT}/include/fftw
    $ENV{FFTW3_ROOT}/include
    $ENV{FFTW_ROOT}/include
    $ENV{FFTWROOT}/include
    $ENV{FFTW3_BASE}/include
    $ENV{FFTW_BASE}/include
    ENV CPATH
    ENV C_INCLUDE_PATH
    ENV CPLUS_INCLUDE_PATH
    ENV OBJC_INCLUDE_PATH
    ENV OBJCPLUS_INCLUDE_PATH
    /usr/include
    /usr/local/include
    /opt/local/include
    /sw/include
  DOC "Include Directory for FFTW"
)

unset(_FFTW_REQ_VARS)
# find_package(BLAS)
# if(BLAS_FOUND AND DEFINED ENV{MKLROOT} AND BLA_VENDOR MATCHES "Intel" OR BLAS_LIBRARIES MATCHES "mkl")
if (FALSE)
  set(FFTW_LIBRARIES "${BLAS_LIBRARIES}")
else()
  if (FFTW_USE_STATIC)
    set(_libname "libfftw3.a")
  else()
    set(_libname "fftw3")
  endif()
  find_library(FFTW_LIBRARIES
    NAMES ${_libname}
    HINTS
      ${FFTW_INCLUDE_DIR}/../lib
      ${FFTW3_ROOT}/lib
      ${FFTW_ROOT}/lib
      $ENV{MKLROOT}/lib/intel64
      $ENV{FFTW3_ROOT}/lib
      $ENV{FFTW_ROOT}/lib
      $ENV{FFTWROOT}/lib
      $ENV{FFTW3_BASE}/lib
      $ENV{FFTW_BASE}/lib
      ENV LIBRARY_PATH
      ENV LD_LIBRARY_PATH
      /usr/lib
      /usr/local/lib
      /opt/local/lib
      /sw/lib
      /lib64
    DOC "FFTW library"
    NO_DEFAULT_PAT
  )
  cmake_policy(SET CMP0057 NEW)
  #
  foreach(PART IN ITEMS MPI OMP Threads)
    if(PART IN_LIST FFTW_FIND_COMPONENTS)
      list(APPEND _FFTW_REQ_VARS "FFTW_${PART}_FOUND")
      string(TOLOWER ${PART} _temp)
      if (FFTW_USE_STATIC)
        set(_libname "libfftw3_${_temp}.a")
      else()
        set(_libname "fftw3_${_temp}")
      endif()
      find_library(FFTW_${PART}_LIBRARIES
        NAMES ${_libname}
        HINTS
          ${FFTW_INCLUDE_DIR}/../lib
          ${FFTW3_ROOT}/lib
          ${FFTW_ROOT}/lib
          $ENV{MKLROOT}/lib/intel64
          $ENV{FFTW3_ROOT}/lib
          $ENV{FFTW_ROOT}/lib
          $ENV{FFTWROOT}/lib
          $ENV{FFTW3_BASE}/lib
          $ENV{FFTW_BASE}/lib
          ENV LIBRARY_PATH
          ENV LD_LIBRARY_PATH
          # /usr/lib
          # /usr/local/lib
          # /opt/local/lib
          # /sw/lib
          DOC "FFTW MPI library"
      )
      unset(_libname)
      list(PREPEND FFTW_LIBRARIES ${FFTW_${PART}_LIBRARIES})
      if (FFTW_${PART}_LIBRARIES STREQUAL "FFTW_${PART}_LIBRARIES-NOTFOUND")
        set(_tmp TRUE)
      else()
        set(_tmp FALSE)
      endif()
      message(STATUS "FFTW_${PART}_LIBRARIES = ${FFTW_${PART}_LIBRARIES} ${_tmp}")
      if(NOT (FFTW_${PART}_LIBRARIES STREQUAL "" OR FFTW_${PART}_LIBRARIES STREQUAL "FFTW_${PART}_LIBRARIES-NOTFOUND"))
        set(FFTW_${PART}_FOUND TRUE)
      endif()
    endif()
  endforeach()
endif()

if(NOT (FFTW_LIBRARIES STREQUAL "" OR FFTW_LIBRARIES STREQUAL "FFTW_LIBRARIES-NOTFOUND" OR FFTW_INCLUDE_DIR STREQUAL "" OR FFTW_INCLUDE_DIR STREQUAL "FFTW_INCLUDE_DIR-NOTFOUND"))
  set(FFTW_FOUND TRUE)
endif()
foreach(PART IN ITEMS MPI OMP Threads)
  if (PART IN_LIST FFTW_FIND_COMPONENTS)
    if (NOT FFTW_${PART}_FOUND)
      set(FFTW_FOUND FALSE)
    endif()
  endif()
endforeach()

### Build FFTW from source ###
if (NOT FFTW_FOUND)

    message(STATUS "Build FFTW from source.")

    # cmake_policy(SET CMP0111 NEW)
    if (POLICY CMP0135)
      cmake_policy(SET CMP0135 OLD)
    endif()

    find_package(Autotools REQUIRED)

    set(_src ${CMAKE_BINARY_DIR}/external/fftw-3.3.10)
    get_filename_component(_src "${_src}" REALPATH)

    set(_install ${CMAKE_BINARY_DIR}/external/fftw)
    file(MAKE_DIRECTORY ${_install})
    file(MAKE_DIRECTORY ${_install}/include)
    get_filename_component(_install "${_install}" REALPATH)

    if (EXISTS "${PROJECT_SOURCE_DIR}/externals/fftw-3.3.10.tar.gz")
      set(SRC_URL "${PROJECT_SOURCE_DIR}/externals/fftw-3.3.10.tar.gz")
    else()
      set(SRC_URL "https://www.fftw.org/fftw-3.3.10.tar.gz")
    endif()

    include(ExternalProject)

    if (NOT TARGET FFTW)
      ExternalProject_Add(FFTW

              URL ${SRC_URL}
              URL_HASH MD5=8ccbf6a5ea78a16dbc3e1306e234cc5c

              SOURCE_DIR ${_src}
              DOWNLOAD_DIR ${_src}
              BUILD_IN_SOURCE true
              CONFIGURE_COMMAND ./configure --prefix=${_install} CC=${CMAKE_C_COMPILER} FC=${CMAKE_Fortran_COMPILER} MPICC=${CMAKE_C_COMPILER} F77=${CMAKE_Fortran_COMPILER}  --enable-fortran --enable-mpi --enable-openmp --enable-threads CFLAGS=-O3 FFLAGS=-O3
              BUILD_COMMAND ${MAKE_EXECUTABLE} -j ${CMAKE_BUILD_PARALLEL_LEVEL}
              INSTALL_COMMAND ${MAKE_EXECUTABLE} install
              BUILD_BYPRODUCTS ${_install}/lib/libfftw3.a ${_install}/lib/libfftw3_mpi.a ${_install}/lib/libfftw3_omp.a ${_install}/lib/libfftw3_threads.a

              USES_TERMINAL_DOWNLOAD ON
              USES_TERMINAL_CONFIGURE ON
              USES_TERMINAL_BUILD ON
              USES_TERMINAL_INSTALL ON
              )
    endif()

    set(FFTW_INCLUDE_DIR "${_install}/include")
    set(FFTW_LIBRARIES "${_install}/lib/libfftw3.a")
    #
    foreach(PART IN ITEMS MPI OMP Threads)
      if(PART IN_LIST FFTW_FIND_COMPONENTS)
        list(APPEND _FFTW_REQ_VARS "FFTW_${PART}_FOUND")
        string(TOLOWER ${PART} _temp)
        set(_libname "libfftw3_${_temp}.a")
        list(PREPEND FFTW_LIBRARIES "${_install}/lib/${_libname}")
        set(FFTW_${PART}_FOUND TRUE)
      endif()
    endforeach()

    set(FFTW_FOUND TRUE)
    set(FFTW_BUILD_FROM_SOURCE TRUE)
endif ()
### End: Build FFTW from source ###


message(STATUS "FFTW_LIBRARIES = ${FFTW_LIBRARIES}")
message(STATUS "FFTW_INCLUDE_DIR = ${FFTW_INCLUDE_DIR}")
include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(
  FFTW
  REQUIRED_VARS FFTW_LIBRARIES FFTW_INCLUDE_DIR ${_FFTW_REQ_VARS}
  HANDLE_COMPONENTS
  )

mark_as_advanced(FFTW_INCLUDE_DIR FFTW_LIBRARIES)

# Interface target
# We refrain from creating an imported target since those cannot be exported
if (FFTW_FOUND AND NOT TARGET FFTW::fftw)
  add_library(FFTW::fftw INTERFACE IMPORTED GLOBAL)
  set_target_properties(FFTW::fftw PROPERTIES
    # IMPORTED_LOCATION "${FFTW_LIBRARIES}"
    INTERFACE_LINK_LIBRARIES "${FFTW_LIBRARIES}"
    INTERFACE_INCLUDE_DIRECTORIES "${FFTW_INCLUDE_DIR}"
  )
  if (FFTW_BUILD_FROM_SOURCE)
    add_dependencies(FFTW::fftw FFTW)
  endif()
endif()
