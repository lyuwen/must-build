# if we have rpc.h then we may *need* it for xdr.h
# so don't only look for xdr.h
find_path(RPC_INCLUDE_DIR "rpc/rpc.h")

# find the lib and add it if found
find_library(RPC_LIBRARIES NAMES rpc xdr_s xdr openxdr)

# might only have xdr.h
if(RPC_INCLUDE_DIR STREQUAL "RPC_INCLUDE_DIR-NOTFOUND")
  find_package(PkgConfig QUIET)
  pkg_check_modules(PC_TIRPC libtirpc)
  #
  find_path(RPC_INCLUDE_DIR
      NAMES netconfig.h
      PATH_SUFFIXES tirpc
      HINTS ${PC_TIRPC_INCLUDE_DIRS}
  )
  find_library(RPC_LIBRARIES
      NAMES tirpc
      HINTS ${PC_TIRPC_LIBRARY_DIRS}
  )
  #
else()
  if(NOT RPC_LIBRARIES STREQUAL "RPC_LIBRARIES-NOTFOUND")
    set(REG_EXTERNAL_LIBS ${REG_EXTERNAL_LIBS} ${RPC_LIBRARIES})
  else()
    set(RPC_LIBRARIES "")
  endif(NOT RPC_LIBRARIES STREQUAL "RPC_LIBRARIES-NOTFOUND")
endif(RPC_INCLUDE_DIR STREQUAL "RPC_INCLUDE_DIR-NOTFOUND")

if(NOT RPC_INCLUDE_DIR STREQUAL "RPC_INCLUDE_DIR-NOTFOUND")
  list(APPEND RPC_INCLUDE_DIR "${RPC_INCLUDE_DIR}/rpc")
endif()

mark_as_advanced(RPC_INCLUDE_DIR RPC_LIBRARIES)

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(RPC DEFAULT_MSG RPC_INCLUDE_DIR)
