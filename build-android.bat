@echo off
REM Script to build libgphoto2 for Android on Windows
REM Requires Android NDK to be installed

setlocal enabledelayedexpansion

REM Configuration
if "%ANDROID_ABI%"=="" set ANDROID_ABI=arm64-v8a
if "%ANDROID_API%"=="" set ANDROID_API=21

echo Building libgphoto2 for Android...
echo ABI: %ANDROID_ABI%
echo API Level: %ANDROID_API%

REM Auto-detect Android NDK if not set
if "%ANDROID_NDK_ROOT%"=="" (
    REM Check common NDK locations
    set NDK_BASE_PATH=C:\Users\gafar\AppData\Local\Android\Sdk\ndk
    
    if exist "!NDK_BASE_PATH!" (
        REM Find the latest NDK version
        for /f "delims=" %%i in ('dir /b /ad /o-n "!NDK_BASE_PATH!" 2^>nul') do (
            set ANDROID_NDK_ROOT=!NDK_BASE_PATH!\%%i
            goto :ndk_found
        )
    )
    
    REM If still not found, check other common locations
    if exist "C:\Android\Sdk\ndk" (
        for /f "delims=" %%i in ('dir /b /ad /o-n "C:\Android\Sdk\ndk" 2^>nul') do (
            set ANDROID_NDK_ROOT=C:\Android\Sdk\ndk\%%i
            goto :ndk_found
        )
    )
    
    echo Error: ANDROID_NDK_ROOT environment variable is not set and NDK not found automatically.
    echo Please install Android NDK and set ANDROID_NDK_ROOT to the NDK path.
    echo Example: set ANDROID_NDK_ROOT=C:\Android\android-ndk-r25c
    exit /b 1
)

:ndk_found

if not exist "%ANDROID_NDK_ROOT%" (
    echo Error: Android NDK not found at %ANDROID_NDK_ROOT%
    exit /b 1
)

echo NDK: %ANDROID_NDK_ROOT%

REM Set up cross-compilation toolchain
set TOOLCHAIN_PREFIX=
if "%ANDROID_ABI%"=="armeabi-v7a" set TOOLCHAIN_PREFIX=armv7a-linux-androideabi
if "%ANDROID_ABI%"=="arm64-v8a" set TOOLCHAIN_PREFIX=aarch64-linux-android
if "%ANDROID_ABI%"=="x86" set TOOLCHAIN_PREFIX=i686-linux-android
if "%ANDROID_ABI%"=="x86_64" set TOOLCHAIN_PREFIX=x86_64-linux-android

if "%TOOLCHAIN_PREFIX%"=="" (
    echo Error: Unsupported ABI %ANDROID_ABI%
    exit /b 1
)

set TOOLCHAIN_DIR=%ANDROID_NDK_ROOT%\toolchains\llvm\prebuilt\windows-x86_64

REM Set up environment
set CC=%TOOLCHAIN_DIR%\bin\clang.exe
set CXX=%TOOLCHAIN_DIR%\bin\clang++.exe
set AR=%TOOLCHAIN_DIR%\bin\llvm-ar.exe
set STRIP=%TOOLCHAIN_DIR%\bin\llvm-strip.exe
set RANLIB=%TOOLCHAIN_DIR%\bin\llvm-ranlib.exe

REM Set target triple for clang
set TARGET_TRIPLE=%TOOLCHAIN_PREFIX%%ANDROID_API%

REM Check if tools exist
if not exist "%CC%" (
    echo Error: Compiler not found at %CC%
    exit /b 1
)

REM Create build directory
set BUILD_DIR=build-android-%ANDROID_ABI%
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
mkdir "%BUILD_DIR%"

echo Configuring build...

REM Check if we have meson
set MESON_CMD=meson
where meson >nul 2>&1
if %errorlevel% neq 0 (
    REM Try common meson locations
    if exist "C:\Users\gafar\AppData\Roaming\Python\Python313\Scripts\meson.exe" (
        set MESON_CMD=C:\Users\gafar\AppData\Roaming\Python\Python313\Scripts\meson.exe
    ) else if exist "%USERPROFILE%\AppData\Roaming\Python\Python313\Scripts\meson.exe" (
        set MESON_CMD=%USERPROFILE%\AppData\Roaming\Python\Python313\Scripts\meson.exe
    ) else if exist "%APPDATA%\..\Roaming\Python\Python313\Scripts\meson.exe" (
        set MESON_CMD=%APPDATA%\..\Roaming\Python\Python313\Scripts\meson.exe
    )
)

REM Check if meson is now available
"%MESON_CMD%" --version >nul 2>&1
if %errorlevel% equ 0 (
    echo Using Meson build system...
    
    REM Create cross-compilation file for Meson
    echo [binaries] > "%BUILD_DIR%\android-cross.txt"
    echo c = ['%CC%', '--target=%TARGET_TRIPLE%'] >> "%BUILD_DIR%\android-cross.txt"
    echo cpp = ['%CXX%', '--target=%TARGET_TRIPLE%'] >> "%BUILD_DIR%\android-cross.txt"
    echo ar = '%AR%' >> "%BUILD_DIR%\android-cross.txt"
    echo strip = '%STRIP%' >> "%BUILD_DIR%\android-cross.txt"
    echo pkg-config = 'pkg-config' >> "%BUILD_DIR%\android-cross.txt"
    echo. >> "%BUILD_DIR%\android-cross.txt"
    echo [host_machine] >> "%BUILD_DIR%\android-cross.txt"
    echo system = 'android' >> "%BUILD_DIR%\android-cross.txt"
    
    if "%ANDROID_ABI%"=="arm64-v8a" (
        echo cpu_family = 'aarch64' >> "%BUILD_DIR%\android-cross.txt"
        echo cpu = 'aarch64' >> "%BUILD_DIR%\android-cross.txt"
    ) else if "%ANDROID_ABI%"=="armeabi-v7a" (
        echo cpu_family = 'arm' >> "%BUILD_DIR%\android-cross.txt"
        echo cpu = 'armv7' >> "%BUILD_DIR%\android-cross.txt"
    ) else if "%ANDROID_ABI%"=="x86_64" (
        echo cpu_family = 'x86_64' >> "%BUILD_DIR%\android-cross.txt"
        echo cpu = 'x86_64' >> "%BUILD_DIR%\android-cross.txt"
    ) else if "%ANDROID_ABI%"=="x86" (
        echo cpu_family = 'x86' >> "%BUILD_DIR%\android-cross.txt"
        echo cpu = 'i686' >> "%BUILD_DIR%\android-cross.txt"
    )
    
    echo endian = 'little' >> "%BUILD_DIR%\android-cross.txt"
    echo. >> "%BUILD_DIR%\android-cross.txt"
    echo [built-in options] >> "%BUILD_DIR%\android-cross.txt"
    echo c_args = ['-fPIC', '-DANDROID', '-D__ANDROID_API__=%ANDROID_API%', '-DHAVE_LTDL=1', '-DHAVE_REGEX=1', '-DHAVE_SERIAL=1', '-DHAVE_STDLIB_H=1', '-DHAVE_UNISTD_H=1', '-DHAVE_STDIO_H=1', '-DHAVE_ERRNO_H=1', '-DHAVE_SYS_TIME_H=1', '-DHAVE_SYS_PARAM_H=1', '-DHAVE_SYS_SELECT_H=1', '-DHAVE_TERMIOS_H=1', '-DHAVE_FCNTL_H=1', '-DHAVE_SYS_IOCTL_H=1', '-DHAVE_TERMIO_H=1', '-DHAVE_ENDIAN_H=1', '-DHAVE_BYTESWAP_H=1', '-DHAVE_MNTENT_H=1', '-DHAVE_SCSI_SG_H=1', '-DHAVE_LIMITS_H=1', '-DHAVE_SYS_FILE_H=1', '-DURL_USB_MASSSTORAGE="http://www.linux-usb.org/USB-guide/x498.html"'] >> "%BUILD_DIR%\android-cross.txt"
    echo cpp_args = ['-fPIC', '-DANDROID', '-D__ANDROID_API__=%ANDROID_API%', '-DHAVE_LTDL=1', '-DHAVE_REGEX=1', '-DHAVE_SERIAL=1', '-DHAVE_STDLIB_H=1', '-DHAVE_UNISTD_H=1', '-DHAVE_STDIO_H=1', '-DHAVE_ERRNO_H=1', '-DHAVE_SYS_TIME_H=1', '-DHAVE_SYS_PARAM_H=1', '-DHAVE_SYS_SELECT_H=1', '-DHAVE_TERMIOS_H=1', '-DHAVE_FCNTL_H=1', '-DHAVE_SYS_IOCTL_H=1', '-DHAVE_TERMIO_H=1', '-DHAVE_ENDIAN_H=1', '-DHAVE_BYTESWAP_H=1', '-DHAVE_MNTENT_H=1', '-DHAVE_SCSI_SG_H=1', '-DHAVE_LIMITS_H=1', '-DHAVE_SYS_FILE_H=1', '-DURL_USB_MASSSTORAGE="http://www.linux-usb.org/USB-guide/x498.html"'] >> "%BUILD_DIR%\android-cross.txt"
    echo c_link_args = ['-static-libgcc', '-ldl'] >> "%BUILD_DIR%\android-cross.txt"
    echo cpp_link_args = ['-static-libgcc', '-ldl'] >> "%BUILD_DIR%\android-cross.txt"
    
    REM Configure with Meson
    cd "%BUILD_DIR%"
    "%MESON_CMD%" setup --cross-file android-cross.txt --default-library=shared --buildtype=release -Dcamlibs="ptp2,directory" -Diolibs="disk" -Ddocs=false ..
    
    if %errorlevel% neq 0 (
        echo Error: Meson configuration failed
        cd ..
        exit /b 1
    )
    
    echo Building...
    "%MESON_CMD%" compile
    
    if %errorlevel% neq 0 (
        echo Error: Build failed
        cd ..
        exit /b 1
    )
    
    echo Android shared libraries built successfully!
    echo Output files:
    dir /s *.so
    cd ..
    
) else (
    echo Meson not found. Please install Meson build system.
    echo You can install it using: pip install meson
    exit /b 1
)

echo.
echo Build completed for Android %ANDROID_ABI%
echo You can find the .so files in the %BUILD_DIR% directory