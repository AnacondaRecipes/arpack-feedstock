
: remove sh.exe from PATH
set PATH=%PATH:C:\Program Files\Git\usr\bin;=%
set PATH=%PATH:C:\Program Files\Git\bin;=%

mkdir build && cd build

:: Static build - configure.
cmake -G "MinGW Makefiles" ^
  -DCMAKE_PREFIX_PATH=%LIBRARY_PREFIX:\=/%/mingw-w64 ^
  -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX:\=/%/mingw-w64 ^
  -DBUILD_SHARED_LIBS=OFF ^
  -DICB=ON ^
  -DEIGEN=ON
  ..
if errorlevel 1 exit 1

:: Build.
mingw32-make install -j %CPU_COUNT%
if errorlevel 1 exit 1

::  Shared build - configure.
cmake -G "MinGW Makefiles" ^
  -DCMAKE_PREFIX_PATH=%LIBRARY_PREFIX:\=/%/mingw-w64 ^
  -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX:\=/%/mingw-w64 ^
  -DBUILD_SHARED_LIBS=ON ^
  -DICB=ON ^
  -DEIGEN=ON
  ..
if errorlevel 1 exit 1

:: Build.
mingw32-make install -j %CPU_COUNT%
if errorlevel 1 exit 1
