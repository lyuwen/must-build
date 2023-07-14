#  Copyright Lyuwen Fu 2022
#    Author: Lyuwen Fu
#
# This module looks for P3DFFT.
# It sets up : P3DFFT_INCLUDE_DIR, P3DFFT_LIBRARIES
# Use P3DFFT_ROOT to specify a particular location
#

if(P3DFFT_INCLUDE_DIR AND P3DFFT_LIBRARIES)
  set(P3DFFT_FIND_QUIETLY TRUE)
endif()

set(P3DFFT_INCLUDE_DIR)
set(P3DFFT_LIBRARIES)
set(P3DFFT_FOUND FALSE)
set(P3DFFT_BUILD_FROM_SOURCE FALSE)

find_path(P3DFFT_INCLUDE_DIR
  NAMES p3dfft.h
  HINTS
    ${P3DFFT_ROOT}/include
    $ENV{P3DFFTROOT}/include
    $ENV{P3DROOT}/include
    $ENV{P3DFFT_ROOT}/include
    $ENV{P3DFFT_BASE}/include
    ENV CPATH
    ENV C_INCLUDE_PATH
    ENV CPLUS_INCLUDE_PATH
    ENV OBJC_INCLUDE_PATH
    ENV OBJCPLUS_INCLUDE_PATH
    /usr/include
    /usr/local/include
    /opt/local/include
    /sw/include
  DOC "Include Directory for P3DFFT"
)

find_library(P3DFFT_LIBRARIES
  NAMES p3dfft
  HINTS
    ${P3DFFT_INCLUDE_DIR}/../lib
    ${P3DFFT_ROOT}/lib
    $ENV{P3DFFTROOT}/lib
    $ENV{P3DROOT}/lib
    $ENV{P3DFFT_ROOT}/lib
    $ENV{P3DFFT_BASE}/lib
    ENV LIBRARY_PATH
    ENV LD_LIBRARY_PATH
    /usr/lib
    /usr/local/lib
    /opt/local/lib
    /sw/lib
  DOC "P3DFFT library"
)

if(NOT (P3DFFT_LIBRARIES STREQUAL "" OR P3DFFT_LIBRARIES STREQUAL "P3DFFT_LIBRARIES-NOTFOUND" OR P3DFFT_INCLUDE_DIR STREQUAL "" OR P3DFFT_INCLUDE_DIR STREQUAL "P3DFFT_INCLUDE_DIR-NOTFOUND"))
  set(P3DFFT_FOUND TRUE)
endif()

### Build P3DFFT from source ###
if (NOT P3DFFT_FOUND)

    message(STATUS "Build P3DFFT from source.")

    # cmake_policy(SET CMP0111 NEW)
    if (POLICY CMP0135)
      cmake_policy(SET CMP0135 OLD)
    endif()

    find_package(Autotools REQUIRED)
    find_package(FFTW REQUIRED MPI)
    # if (FFTW_INTEL)
    #   set(_WITHFFTW "")
    # else()
      get_filename_component(_FFTW_ROOT "${FFTW_INCLUDE_DIR}" DIRECTORY)
      set(_WITHFFTW "--with-fftw=${_FFTW_ROOT}")
    # endif()
    message(STATUS "Find FFTW to build with P3DFFT: ${_WITHFFTW}")

    set(_src ${CMAKE_BINARY_DIR}/external/p3dfft-2.7.9)
    get_filename_component(_src "${_src}" REALPATH)

    set(_install ${CMAKE_BINARY_DIR}/external/p3dfft)
    file(MAKE_DIRECTORY ${_install})
    file(MAKE_DIRECTORY ${_install}/include)
    get_filename_component(_install "${_install}" REALPATH)

    if (EXISTS "${PROJECT_SOURCE_DIR}/externals/p3dfft-2.7.9.tar.gz")
      set(SRC_URL "${PROJECT_SOURCE_DIR}/externals/p3dfft-2.7.9.tar.gz")
    else()
      set(SRC_URL "https://github.com/sdsc/p3dfft/archive/refs/tags/2.7.9.tar.gz")
    endif()
    message(STATUS "P3DFFT source from: ${SRC_URL}")

    include(ExternalProject)

    ExternalProject_Add(P3DFFT

            URL ${SRC_URL}
            URL_HASH MD5=09c38e4b50cd23229095409b904c1fb9

            SOURCE_DIR ${_src}
            DOWNLOAD_DIR ${_src}
            BUILD_IN_SOURCE true
            CONFIGURE_COMMAND ./configure --prefix=${_install} --enable-fftw ${_WITHFFTW} --enable-intel FC=${CMAKE_Fortran_COMPILER} CC=${CMAKE_C_COMPILER}
            BUILD_COMMAND ${MAKE_EXECUTABLE} -j ${CMAKE_BUILD_PARALLEL_LEVEL}
            INSTALL_COMMAND ${MAKE_EXECUTABLE} install
            BUILD_BYPRODUCTS ${_install}/lib/libp3dfft.a

            USES_TERMINAL_DOWNLOAD ON
            USES_TERMINAL_CONFIGURE ON
            USES_TERMINAL_BUILD ON
            USES_TERMINAL_INSTALL ON
            )
    add_dependencies(P3DFFT FFTW)

    set(P3DFFT_INCLUDE_DIR "${_install}/include")
    set(P3DFFT_LIBRARIES "${_install}/lib/libp3dfft.a")
    #

    set(P3DFFT_FOUND TRUE)
    set(P3DFFT_BUILD_FROM_SOURCE TRUE)
endif ()
### End: Build P3DFFT from source ###


include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(
  P3DFFT
  DEFAULT_MSG
  P3DFFT_LIBRARIES
  P3DFFT_INCLUDE_DIR
  )

if (P3DFFT_FOUND AND NOT TARGET P3DFFT::P3DFFT)
  add_library(P3DFFT::P3DFFT STATIC IMPORTED)
  set_target_properties(P3DFFT::P3DFFT PROPERTIES
    IMPORTED_LOCATION "${P3DFFT_LIBRARIES}"
    INTERFACE_INCLUDE_DIRECTORIES "${P3DFFT_INCLUDE_DIR}"
  )
if (P3DFFT_BUILD_FROM_SOURCE)
    add_dependencies(P3DFFT::P3DFFT P3DFFT)
  endif()
endif()

mark_as_advanced(P3DFFT_INCLUDE_DIR P3DFFT_LIBRARIES)
