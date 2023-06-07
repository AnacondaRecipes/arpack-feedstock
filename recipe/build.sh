#!/bin/sh

set -x

mkdir build && cd build

if [[ "$(echo $fortran_compiler_version | cut -d '.' -f 1)" -gt 9 ]]; then
  export FFLAGS="$FFLAGS -fallow-argument-mismatch"
fi

case "${blas_impl}" in
        mkl)
            export BLAS="MKL"
            export USE_MKL=1
            export USE_MKLDNN=1
	    export BLA_VENDOR="Intel"
            ;;
        openblas)
            export BLAS="OpenBLAS"
            export USE_MKL=0
            export USE_MKLDNN=0
	    export BLA_VENDOR="OpenBLAS"
            ;;
        *)
            echo "[ERROR] Unsupported BLAS implementation '${blas_impl}'" >&2
            exit 1
            ;;
    esac

if [[ ${HOST} =~ .*linux.* ]]; then
  # Need to point to libquadmath.so.0
  export LD_LIBRARY_PATH=${PREFIX}/lib:$LD_LIBRARY_PATH
fi

if [[ ${HOST} =~ .*darwin.* ]]; then
  export LIBS="$LIBS -framework Accelerate"
  export FFLAGS="$FFLAGS -ff2c -fno-second-underscore"
  export FCFLAGS="$FCFLAGS -ff2c -fno-second-underscore"
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
  ctest --output-on-failure -j${CPU_COUNT}
fi
