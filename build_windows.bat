@echo off
cd /d %~dp0

SETLOCAL
for /f delims^=^"^ tokens^=2 %%i IN ('type .\CMakeLists.txt ^| find "stremio VERSION"') DO (
   set package_version=%%i
)

SET BUILD_DIR=build
SET "OPENSSL_BIN64=C:\OpenSSL-Win64\bin"
SET "OPENSSL_BIN32=C:\OpenSSL-Win32\bin"
SET "OPENSSL_BIN_PATH="
IF EXIST "%OPENSSL_BIN64%" (
    SET "OPENSSL_BIN_PATH=%OPENSSL_BIN64%"
) ELSE IF EXIST "%OPENSSL_BIN32%" (
    SET "OPENSSL_BIN_PATH=%OPENSSL_BIN32%"
)
IF "%OPENSSL_BIN_PATH%"=="" (
    ECHO OpenSSL installation not found. Please install Win64 OpenSSL and retry.
    EXIT /B 1
)

:: Set up VS environment
CALL "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x86

IF NOT EXIST "%BUILD_DIR%" mkdir "%BUILD_DIR%"
PUSHD "%BUILD_DIR%"

cmake -G"NMake Makefiles" -DCMAKE_BUILD_TYPE=Release ..
::exit /b
cmake --build .

POPD

rd /s/q dist-win
md dist-win

::copy "C:\Program Files (x86)\nodejs\node.exe" dist-win\stremio-runtime.exe
@REM CALL windows\generate_stremio-runtime.cmd dist-win
powershell -Command Start-BitsTransfer -Source "$(cat .\server-url.txt)" -Destination .\dist-win\server.js; ((Get-Content -path .\dist-win\server.js -Raw) -replace 'os.tmpDir','os.tmpdir') ^| Set-Content -Path .\dist-win\server.js
copy build\*.exe dist-win
copy windows\*.dll dist-win
copy windows\*.exe dist-win
copy windows\DS\* dist-win
for %%F in (libcrypto-3-x64.dll libssl-3-x64.dll libcrypto-3.dll libssl-3.dll libcrypto-1_1-x64.dll libssl-1_1-x64.dll libcrypto-1_1.dll libssl-1_1.dll) do (
    if exist "%OPENSSL_BIN_PATH%\%%~F" copy "%OPENSSL_BIN_PATH%\%%~F" dist-win >nul
)
windeployqt --release --no-compiler-runtime --qmldir=. ./dist-win/stremio.exe
"C:\Program Files (x86)\NSIS\makensis.exe" windows\installer\windows-installer.nsi
ENDLOCAL
