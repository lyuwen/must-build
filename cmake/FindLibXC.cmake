#  Copyright Lyuwen Fu 2022
#    Author: Lyuwen Fu
#
# This module looks for LibXC.
# It sets up : LibXC_INCLUDE_DIR, LibXC_LIBRARIES
# Use LibXC_ROOT to specify a particular location
#

if(LibXC_INCLUDE_DIR AND LibXC_LIBRARIES)
  set(LibXC_FIND_QUIETLY TRUE)
endif()

set(LibXC_INCLUDE_DIR)
set(LibXC_LIBRARIES)
set(LibXC_FOUND FALSE)
set(LibXC_BUILD_FROM_SOURCE FALSE)
foreach(PART IN ITEMS Fortran Fortran03)
  set(LibXC_${PART}_FOUND FALSE)
endforeach()
unset(_LibXC_REQ_VARS)

find_path(LibXC_INCLUDE_DIR
  NAMES xc.h
  HINTS
    ${LIBXC_ROOT}/include
    $ENV{LIBXCROOT}/include
    $ENV{LIBXC_ROOT}/include
    $ENV{LIBXC_BASE}/include
    ENV CPATH
    ENV C_INCLUDE_PATH
    ENV CPLUS_INCLUDE_PATH
    ENV OBJC_INCLUDE_PATH
    ENV OBJCPLUS_INCLUDE_PATH
    /usr/include
    /usr/local/include
    /opt/local/include
    /sw/include
  DOC "Include Directory for LibXC"
)
message(STATUS "LibXC_INCLUDE_DIR = ${LibXC_INCLUDE_DIR}")

find_library(LibXC_LIBRARIES
  NAMES xc
  HINTS
    ${LIBXC_INCLUDE_DIR}/../lib
    ${LIBXC_ROOT}/lib
    $ENV{LIBXCROOT}/lib
    $ENV{LIBXC_ROOT}/lib
    $ENV{LIBXC_BASE}/lib
    ENV LIBRARY_PATH
    ENV LD_LIBRARY_PATH
    /usr/lib
    /usr/local/lib
    /opt/local/lib
    /sw/lib
  DOC "LibXC library"
)

cmake_policy(SET CMP0057 NEW)
foreach(PART IN ITEMS Fortran Fortran03)
  if(PART IN_LIST LibXC_FIND_COMPONENTS)
    list(APPEND _LibXC_REQ_VARS "LibXC_${PART}_FOUND")
    string(TOLOWER ${PART} _temp)
    if (PART EQUAL "Fortran03")
      set(_libname "xcf03")
    else()
      set(_libname "xcf90")
    endif()
    find_library(LibXC_${PART}_LIBRARIES
      NAMES ${_libname}
      HINTS
        ${LIBXC_INCLUDE_DIR}/../lib
        ${LIBXC_ROOT}/lib
        $ENV{LIBXCROOT}/lib
        $ENV{LIBXC_ROOT}/lib
        $ENV{LIBXC_BASE}/lib
        ENV LIBRARY_PATH
        ENV LD_LIBRARY_PATH
        /usr/lib
        /usr/local/lib
        /opt/local/lib
        /sw/lib
      DOC "LibXC ${PART} library"
    )
    if(NOT (LibXC_${PART}_LIBRARIES STREQUAL "" OR LibXC_${PART}_LIBRARIES STREQUAL "LibXC_${PART}_LIBRARIES-NOTFOUND"))
      set(LibXC_${PART}_FOUND TRUE)
    endif()
    list(PREPEND LibXC_LIBRARIES ${LibXC_${PART}_LIBRARIES})
  endif()
endforeach()

message(STATUS "LibXC_LIBRARIES = ${LibXC_LIBRARIES}")

if(NOT (LibXC_LIBRARIES STREQUAL "" OR LibXC_LIBRARIES STREQUAL "LibXC_LIBRARIES-NOTFOUND" OR LibXC_INCLUDE_DIR STREQUAL "" OR LibXC_INCLUDE_DIR STREQUAL "LibXC_INCLUDE_DIR-NOTFOUND"))
  set(LibXC_FOUND TRUE)
endif()

foreach(PART IN ITEMS Fortran Fortran03)
  if (PART IN_LIST FFTW_FIND_COMPONENTS)
    message(STATUS "test: ${PART} ${FFTW_${PART}_FOUND}")
    if (NOT FFTW_${PART}_FOUND)
      set(FFTW_FOUND FALSE)
    endif()
  endif()
endforeach()

### Build LibXC from source ###
if (NOT LibXC_FOUND)

    message(STATUS "Build LibXC from source.")
    # cmake_policy(SET CMP0111 NEW)
    if (POLICY CMP0135)
      cmake_policy(SET CMP0135 OLD)
    endif()

    find_package(Autotools REQUIRED)

    set(_src ${CMAKE_BINARY_DIR}/external/libxc-5.2.3)
    get_filename_component(_src "${_src}" REALPATH)

    set(_install ${CMAKE_BINARY_DIR}/external/libxc)
    file(MAKE_DIRECTORY ${_install})
    file(MAKE_DIRECTORY ${_install}/include)
    get_filename_component(_install "${_install}" REALPATH)

    if (EXISTS "${PROJECT_SOURCE_DIR}/externals/libxc-5.2.3.tar.gz")
      set(SRC_URL "${PROJECT_SOURCE_DIR}/externals/libxc-5.2.3.tar.gz")
    else()
      set(SRC_URL "http://www.tddft.org/programs/libxc/down.php?file=5.2.3/libxc-5.2.3.tar.gz")
    endif()
    message(STATUS "LibXC source from: ${SRC_URL}")

    include(ExternalProject)

    ExternalProject_Add(LibXC

            URL ${SRC_URL}
            URL_HASH MD5=53cf32cf9c0142a42650cc538de16dcf
            # GIT_REPOSITORY https://github.com/ElectronicStructureLibrary/libxc.git
            # GIT_TAG 5.2.3
            # GIT_SHALLOW ON
            # GIT_PROGRESS ON

            SOURCE_DIR ${_src}
            DOWNLOAD_DIR ${_src}
            BUILD_IN_SOURCE true
            CONFIGURE_COMMAND ./configure --prefix=${_install} CC=${CMAKE_C_COMPILER} FC=${CMAKE_Fortran_COMPILER} "CFLAGS=-std=c99 -O3" FFLAGS=-O3
            BUILD_COMMAND ${MAKE_EXECUTABLE} -j ${CMAKE_BUILD_PARALLEL_LEVEL}
            INSTALL_COMMAND ${MAKE_EXECUTABLE} install
            BUILD_BYPRODUCTS ${_install}/lib/libxc.a

            USES_TERMINAL_DOWNLOAD ON
            USES_TERMINAL_CONFIGURE ON
            USES_TERMINAL_BUILD ON
            USES_TERMINAL_INSTALL ON
            )

    set(LibXC_INCLUDE_DIR "${_install}/include")
    set(LibXC_LIBRARIES "${_install}/lib/libxc.a")
    if("Fortran" IN_LIST LibXC_FIND_COMPONENTS)
      list(PREPEND LibXC_LIBRARIES "${_install}/lib/libxcf90.a")
      set(LibXC_Fortran_FOUND TRUE)
      list(APPEND _LibXC_REQ_VARS "LibXC_Fortran_FOUND")
    endif()
    if("Fortran03" IN_LIST LibXC_FIND_COMPONENTS)
      list(PREPEND LibXC_LIBRARIES "${_install}/lib/libxcf03.a")
      set(LibXC_Fortran03_FOUND TRUE)
      list(APPEND _LibXC_REQ_VARS "LibXC_Fortran03_FOUND")
    endif()

    set(LibXC_FOUND TRUE)
    set(LibXC_BUILD_FROM_SOURCE TRUE)
endif ()
### End: Build LibXC from source ###


include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(
  LibXC
  REQUIRED_VARS LibXC_LIBRARIES LibXC_INCLUDE_DIR ${_LibXC_REQ_VARS}
  HANDLE_COMPONENTS
  )

if (LibXC_FOUND AND NOT TARGET LibXC::libxc)
  add_library(LibXC::libxc INTERFACE IMPORTED)
  set_target_properties(LibXC::libxc PROPERTIES
    # IMPORTED_LOCATION "${LibXC_LIBRARIES}"
    INTERFACE_LINK_LIBRARIES "${LibXC_LIBRARIES}"
    INTERFACE_INCLUDE_DIRECTORIES "${LibXC_INCLUDE_DIR}"
  )
  if (LibXC_BUILD_FROM_SOURCE)
    add_dependencies(LibXC::libxc LibXC)
  endif()
endif()

mark_as_advanced(LibXC_INCLUDE_DIR LibXC_LIBRARIES)
