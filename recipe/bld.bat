mkdir build && cd build
if errorlevel 1 exit 1

if "%blas_impl%"=="mkl" (
  set "BLA_VENDOR=Intel10_64lp_seq"
) else (
  set "BLA_VENDOR=OpenBLAS"
)

:: Static build
cmake -G "Ninja" ^
  -DCMAKE_PREFIX_PATH=%LIBRARY_PREFIX:\=/% ^
  -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX:\=/% ^
  -DBUILD_SHARED_LIBS=OFF ^
  -DICB=ON ^
  -DTESTS=OFF ^
  -DEXAMPLES=OFF ^
  -DBLA_VENDOR=%BLA_VENDOR% ^
  ..
if errorlevel 1 exit 1

ninja install -j %CPU_COUNT%
if errorlevel 1 exit 1

:: Shared build
cmake -G "Ninja" ^
  -DCMAKE_PREFIX_PATH=%LIBRARY_PREFIX:\=/% ^
  -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX:\=/% ^
  -DBUILD_SHARED_LIBS=ON ^
  -DICB=ON ^
  -DTESTS=OFF ^
  -DEXAMPLES=OFF ^
  -DBLA_VENDOR=%BLA_VENDOR% ^
  ..
if errorlevel 1 exit 1

ninja install -j %CPU_COUNT%
if errorlevel 1 exit 1
