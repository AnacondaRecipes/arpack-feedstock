#!/bin/sh

set -x

mkdir build && cd build

if [[ "$(echo $fortran_compiler_version | cut -d '.' -f 1)" -gt 9 ]]; then
  export FFLAGS="$FFLAGS -fallow-argument-mismatch"
fi

if [[ ${HOST} =~ .*linux.* ]]; then
  # Need to point to libquadmath.so.0
  export LD_LIBRARY_PATH=${PREFIX}/lib:$LD_LIBRARY_PATH
fi

if [[ ${HOST} =~ .*darwin.* ]]; then
  export LIBS="$LIBS -framework Accelerate"
  export FFLAGS="$FFLAGS -ff2c -fno-second-underscore"
  export FCFLAGS="$FCFLAGS -ff2c -fno-second-underscore"
fi

export BLA_VENDOR=OpenBLAS
OPENBLAS_LIB="${PREFIX}/lib/libopenblas${SHLIB_EXT}"
MATHLIB=""
if [[ ${HOST} =~ .*linux.* ]]; then
  MATHLIB=";m"
fi

for shared_libs in OFF ON
do
  cmake ${CMAKE_ARGS} \
    -DCMAKE_PREFIX_PATH=${PREFIX} \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DBUILD_SHARED_LIBS=${shared_libs} \
    -DICB=ON \
    -DMPI=${DMPI} \
    -DBUILD_TESTING=OFF \
    -DTESTS=OFF \
    -DEXAMPLES=OFF \
    -DBLA_VENDOR=OpenBLAS \
    -DBLAS_LIBRARIES="${OPENBLAS_LIB}${MATHLIB}" \
    -DLAPACK_LIBRARIES="${OPENBLAS_LIB}${MATHLIB}" \
    ..

  if [[ ${HOST} =~ .*darwin.* ]]; then
    if [[ ${mpi} != 'nompi' ]]; then
      sed -i '' "s/-fallow-argument-mismatch//g" $SRC_DIR/build/CMakeFiles/icb_parpack_cpp.dir/flags.make
      sed -i '' "s/-fallow-argument-mismatch//g" $SRC_DIR/build/CMakeFiles/icb_parpack_c.dir/flags.make
    fi
  fi
  make install -j${CPU_COUNT} VERBOSE=1
done

if [[ "${CONDA_BUILD_CROSS_COMPILATION}" != "1" ]]; then
  # Do not run the test on osx as this test causes OS crashes on certain osx configurations.
  if [[ ${HOST} =~ .*linux.* ]]; then
    ctest --output-on-failure -j${CPU_COUNT}
  fi
fi
