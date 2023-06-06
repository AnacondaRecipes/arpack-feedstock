#!/bin/sh

set -x

mkdir build && cd build

if [[ "$(echo $fortran_compiler_version | cut -d '.' -f 1)" -gt 9 ]]; then
  export FFLAGS="$FFLAGS -fallow-argument-mismatch"
fi

for shared_libs in OFF ON
do
  cmake ${CMAKE_ARGS} \
    -DCMAKE_PREFIX_PATH=${PREFIX} \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DBUILD_SHARED_LIBS=${shared_libs} \
    -DBLAS_LIBRARIES="-lopenblas" \
    -DICB=ON \
    -DMPI=${DMPI} \
    ..
  make install -j${CPU_COUNT} VERBOSE=1
done

if [[ "${CONDA_BUILD_CROSS_COMPILATION}" != "1" ]]; then
  # Need to point to libquadmath.so.0 for tests to pass...
  export LD_LIBRARY_PATH=${PREFIX}/lib:$LD_LIBRARY_PATH
  ctest --output-on-failure -j${CPU_COUNT}
fi
