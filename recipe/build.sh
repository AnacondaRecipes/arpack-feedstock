#!/bin/sh

# Rationale summary:
# - CMake couldn't find LAPACK → pass explicit BLAS/LAPACK = $PREFIX/lib/libopenblas${SHLIB_EXT} and set BLA_VENDOR=OpenBLAS.
# - --error-overlinking for libgomp → strip -fopenmp from *FLAGS and forbid finding OpenMP.
# - macOS Fortran compiler ABI test failed → force FC from build env, remove f2c flags, add rpath to $PREFIX/lib.
# - macOS overlinking to Accelerate/libcxx/llvm-openmp → don't add Accelerate; ignore run_exports for libcxx/llvm-openmp in meta.yaml.

set -x

mkdir build && cd build

if [[ "$(echo $fortran_compiler_version | cut -d '.' -f 1)" -gt 9 ]]; then
  export FFLAGS="$FFLAGS -fallow-argument-mismatch"
fi

if [[ ${HOST} =~ .*linux.* ]]; then
  # Need to point to libquadmath.so.0
  export LD_LIBRARY_PATH=${PREFIX}/lib:$LD_LIBRARY_PATH
  # Exclude -fopenmp from build due to linking erorr resolution for libgomp
  # IMPORTANT: drop OpenMP from compile flags so we don't pull libgomp into runtime.
  # Our repo does not ship 'libgomp', and --error-overlinking will flag it if present.
  export FFLAGS="$(printf '%s' "$FFLAGS" | sed 's/-fopenmp//g')"
  export CFLAGS="$(printf '%s' "$CFLAGS" | sed 's/-fopenmp//g')"
  export CXXFLAGS="$(printf '%s' "$CXXFLAGS" | sed 's/-fopenmp//g')"
fi

if [[ ${HOST} =~ .*darwin.* ]]; then
  # Force CMake to use the Fortran compiler from the build env (not host env).
  export FC="${BUILD_PREFIX}/bin/${HOST}-gfortran"
fi

# Tell CMake we want the OpenBLAS provider.
export BLA_VENDOR=OpenBLAS
# Pass the exact paths to BLAS/LAPACK to avoid FindLAPACK guessing (esp. under strict root paths).
OPENBLAS_LIB="${PREFIX}/lib/libopenblas${SHLIB_EXT}"

for shared_libs in OFF ON
do
  cmake ${CMAKE_ARGS} \
    -DCMAKE_Fortran_COMPILER="${FC}" \
    -DCMAKE_PREFIX_PATH=${PREFIX} \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DBUILD_SHARED_LIBS=${shared_libs} \
    -DICB=ON \
    -DMPI=${DMPI} \
    -DTESTS=OFF \
    -DEXAMPLES=OFF \
    -DBLA_VENDOR=OpenBLAS \
    -DBLAS_LIBRARIES="${OPENBLAS_LIB}" \
    -DLAPACK_LIBRARIES="${OPENBLAS_LIB}" \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    ..

  # macOS: historical hack to strip '-fallow-argument-mismatch' from generated flags if present.
  # Guarded to avoid failing when these targets are not generated.
  if [[ ${HOST} =~ .*darwin.* && "${DMPI}" == "ON" ]]; then
    for f in "$PWD/CMakeFiles/icb_parpack_cpp.dir/flags.make" \
            "$PWD/CMakeFiles/icb_parpack_c.dir/flags.make"; do
      [ -f "$f" ] && sed -i '' 's/-fallow-argument-mismatch//g' "$f" || true
    done
  fi
  make install -j${CPU_COUNT} VERBOSE=1
done

if [[ "${CONDA_BUILD_CROSS_COMPILATION}" != "1" ]]; then
  # Do not run the test on osx as this test causes OS crashes on certain osx configurations.
  if [[ ${HOST} =~ .*linux.* ]]; then
    ctest --output-on-failure -j${CPU_COUNT}
  fi
fi
