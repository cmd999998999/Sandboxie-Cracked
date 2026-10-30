call "%~dp0..\Installer\buildVariables.cmd" %*

REM Use the pinned stock Qt build only when CodeQL explicitly requests it.
IF /I "%~3"=="--codeql" (
  IF NOT DEFINED qt_codeql_version (
    echo ERROR: qt_codeql_version is not configured
    exit /b 1
  )
  setlocal
  set "qt_version=%qt_codeql_version%"
)

REM CLI-only fork: disable the Qt GUI front-end and SandMan components.
REM Only build the still-useful backend/library pieces required by the CLI path.
REM The GUI stack is intentionally excluded.

IF %1 == Win32 (
  set qt_path=%~dp0..\..\Qt\%qt_version%\msvc2022
  Xcopy /E /I /Y /Q %~dp0..\..\Qt\%qt_version%\msvc2022\include\QtCore\%qt_version%\QtCore %~dp0..\..\Qt\%qt_version%\msvc2022\include\QtCore
  set build_arch=Win32
  set qt_params= 
  call "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars32.bat"
)
IF %1 == x64 (
  set qt_path=%~dp0..\..\Qt\%qt_version%\msvc2022_64
  Xcopy /E /I /Y /Q %~dp0..\..\Qt\%qt_version%\msvc2022_64\include\QtCore\%qt_version%\QtCore %~dp0..\..\Qt\%qt_version%\msvc2022_64\include\QtCore
  set build_arch=x64
  set qt_params= 
  call "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
)
IF %1 == ARM64 (
  set qt_path=%~dp0..\..\Qt\%qt6_version%\msvc2022_64
  Xcopy /E /I /Y /Q %~dp0..\..\Qt\%qt6_version%\msvc2022_arm64\include\QtCore\%qt6_version%\QtCore %~dp0..\..\Qt\%qt6_version%\msvc2022_arm64\include\QtCore
  set build_arch=ARM64
  echo [DevicePaths] > %~dp0..\..\Qt\%qt6_version%\msvc2022_arm64\bin\my_target_qt.conf
  echo Prefix=C:/Qt/Qt-%qt6_version% >> %~dp0..\..\Qt\%qt6_version%\msvc2022_arm64\bin\my_target_qt.conf
  echo [Paths] >> %~dp0..\..\Qt\%qt6_version%\msvc2022_arm64\bin\my_target_qt.conf
  echo Prefix=../ >> %~dp0..\..\Qt\%qt6_version%\msvc2022_arm64\bin\my_target_qt.conf
  echo HostPrefix=../../msvc2022_64 >> %~dp0..\..\Qt\%qt6_version%\msvc2022_arm64\bin\my_target_qt.conf
  echo HostData=../msvc2022_arm64 >> %~dp0..\..\Qt\%qt6_version%\msvc2022_arm64\bin\my_target_qt.conf
  echo Sysroot= >> %~dp0..\..\Qt\%qt6_version%\msvc2022_arm64\bin\my_target_qt.conf
  echo SysrootifyPrefix=false >> %~dp0..\..\Qt\%qt6_version%\msvc2022_arm64\bin\my_target_qt.conf
  echo TargetSpec=win32-arm64-msvc >> %~dp0..\..\Qt\%qt6_version%\msvc2022_arm64\bin\my_target_qt.conf
  echo HostSpec=win32-msvc >> %~dp0..\..\Qt\%qt6_version%\msvc2022_arm64\bin\my_target_qt.conf
  echo Documentation=../../Docs/Qt-%qt6_version% >> %~dp0..\..\Qt\%qt6_version%\msvc2022_arm64\bin\my_target_qt.conf
  echo Examples=../../Examples/Qt-%qt6_version% >> %~dp0..\..\Qt\%qt6_version%\msvc2022_arm64\bin\my_target_qt.conf
  set qt_params=-qtconf "%~dp0..\..\Qt\%qt6_version%\msvc2022_arm64\bin\my_target_qt.conf"
  call "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvarsamd64_arm64.bat"
)
@echo on

REM CLI-only fork: do not build SandMan or GUI helper libraries.
mkdir %~dp0\Build_MiscHelpers_%build_arch%
cd %~dp0\Build_MiscHelpers_%build_arch%
%qt_path%\bin\qmake.exe %~dp0\MiscHelpers\MiscHelpers.qc.pro %qt_params%
%~dp0..\..\Qt\Tools\QtCreator\bin\jom.exe -f Makefile.Release -j 8
IF %ERRORLEVEL% NEQ 0 goto :error
if NOT EXIST %~dp0\bin\%build_arch%\Release\MiscHelpers.dll goto :error

mkdir %~dp0\Build_QSbieAPI_%build_arch%
cd %~dp0\Build_QSbieAPI_%build_arch%
%qt_path%\bin\qmake.exe %~dp0\QSbieAPI\QSbieAPI.qc.pro %qt_params%
%~dp0..\..\Qt\Tools\QtCreator\bin\jom.exe -f Makefile.Release -j 8
IF %ERRORLEVEL% NEQ 0 goto :error
if NOT EXIST %~dp0\bin\%build_arch%\Release\QSbieAPI.dll goto :error

echo CLI-only fork build complete.
echo GUI stack disabled: SandMan, QtSingleApp, UGlobalHotkey.

cd %~dp0

goto :eof

:error
echo Build failed
exit 1
