@echo off
:: setlocal ensures any variables or PATH changes made here DO NOT bleed into your actual system
setlocal EnableDelayedExpansion

TITLE P-ROC and CCC Dynamic Safe Installer

:: -----------------------------------------------------------------------------
:: 1. UAC Elevation Check
:: -----------------------------------------------------------------------------
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    cscript //NoLogo "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"

:: -----------------------------------------------------------------------------
:: 2. Target Drive Selection & Setup
:: -----------------------------------------------------------------------------
echo ===================================================
echo   P-ROC 1.27.03 ^& CCC Installer
echo ===================================================
echo.
set /p TARGET_DRIVE="Enter the drive letter where you want to install (e.g., C, D, E): "
set TARGET_DRIVE=%TARGET_DRIVE:~0,1%

SET OUTDIR=%TARGET_DRIVE%:\P-ROC
SET PY_DIR=%TARGET_DRIVE%:\Python27
SET MINGW_DIR=%TARGET_DRIVE%:\MinGW
SET UNINST_KEY=HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
SET ZIP_TOOL="%~dp0resources\7z\%PROCESSOR_ARCHITECTURE%\7z.exe"

IF "%PROCESSOR_ARCHITECTURE%"=="x86" (
    SET SYS_DIR=%SYSTEMROOT%\System32
) ELSE (
    SET SYS_DIR=%SYSTEMROOT%\SysWOW64
)

echo.
echo Installing to %TARGET_DRIVE%:\ ...
echo.

:: -----------------------------------------------------------------------------
:: 3. Core Prerequisites
:: -----------------------------------------------------------------------------
echo [1/4] Extracting Core Files and MinGW...
%ZIP_TOOL% x -y -bd "%~dp0resources\P-ROC.7z" -o%TARGET_DRIVE%:\ >nul || call :fail "Failed to extract P-ROC folder."
xcopy /Y "%OUTDIR%\$WINDIR\SysWOW64\ftd2xx.dll" "%SYS_DIR%\" >nul 2>nul

%ZIP_TOOL% x -y -bd "%~dp0resources\MinGW.7z" -o%TARGET_DRIVE%:\ >nul || call :fail "Failed to extract MinGW."

echo Building YamlCPP and LibPinProc...
Start /wait %OUTDIR%\scripts\yaml-install.bat || call :fail "YamlCPP Installation failed."
Start /wait %OUTDIR%\scripts\libpinproc-install.bat || call :fail "LibPinProc Installation failed."

echo Installing FTDI Driver...
Start /wait %OUTDIR%\ftdi\dpinst-%PROCESSOR_ARCHITECTURE%.exe /S /SE

echo Installing Python 2.7...
Start /wait msiexec /i "%~dp0resources\python-2.7.13.msi" TARGETDIR=%PY_DIR% /qn ALLUSERS=1 || call :fail "Python 2.7 Installation failed."
xcopy /y "%PY_DIR%\Libs\libpython27.a" "%MINGW_DIR%\lib\" >nul 2>nul

:: SAFE PATH INJECTION (Dynamic): 
echo Setting up temporary local paths...
SET "PATH=%MINGW_DIR%\bin;%OUTDIR%\cmake\bin;%PY_DIR%\Scripts;%PY_DIR%;%PATH%"

:: -----------------------------------------------------------------------------
:: 4. Python Modules (Strict Absolute Paths)
:: -----------------------------------------------------------------------------
echo.
echo [2/4] Installing Python Modules...

:: Force bootstrap pip just in case the silent MSI skipped it during reinstall
"%PY_DIR%\python.exe" -m ensurepip >nul 2>&1

cd /d "%OUTDIR%\pypinproc"
"%PY_DIR%\python.exe" setup.py install build --compiler=mingw32 || call :fail "PyPinProc failed."

cd /d "%OUTDIR%\tmp"
"%PY_DIR%\python.exe" -m pip install PyYAML-3.12-cp27-cp27m-win32.whl || call :fail "PyYAML failed."
"%PY_DIR%\python.exe" -m pip install pygame-1.9.3-cp27-cp27m-win32.whl || call :fail "PyGame failed."

cd /d "%OUTDIR%\pyprocgame"
"%PY_DIR%\python.exe" setup.py install || call :fail "PyProcGame failed."
if not exist "%USERPROFILE%\.pyprocgame\" mkdir "%USERPROFILE%\.pyprocgame\"
xcopy /Y "%OUTDIR%\$USERDIR\config.yaml" "%USERPROFILE%\.pyprocgame\" >nul

cd /d "%OUTDIR%\tmp\olefile-0.44"
"%PY_DIR%\python.exe" setup.py install || call :fail "Olefile failed."

cd /d "%OUTDIR%\tmp\"
"%PY_DIR%\python.exe" -m pip install Pillow-4.1.1-cp27-cp27m-win32.whl || call :fail "Pillow failed."

cd /d "%OUTDIR%\tmp\pyOSC-0.3.5b-5294"
"%PY_DIR%\python.exe" setup.py install || call :fail "PyOSC failed."

cd /d "%OUTDIR%\tmp\PySDL2-0.9.5"
"%PY_DIR%\python.exe" setup.py install || call :fail "PySDL2 failed."

cd /d "%OUTDIR%\tmp\"
"%PY_DIR%\python.exe" -m pip install numpy-1.11.3+mkl-cp27-cp27m-win32.whl || call :fail "Numpy failed."
"%PY_DIR%\python.exe" -m pip install opencv_python-2.4.13.2-cp27-cp27m-win32.whl || call :fail "OpenCV failed."
"%PY_DIR%\python.exe" -m pip install pywin32-221-cp27-cp27m-win32.whl || call :fail "PyWin32 failed."

cd /d "%PY_DIR%\Scripts"
"%PY_DIR%\python.exe" pywin32_postinstall.py -install || call :fail "PyWin32 Post-install failed."

:: -----------------------------------------------------------------------------
:: 5. Cactus Canyon Continued (CCC) Assets
:: -----------------------------------------------------------------------------
echo.
echo [3/4] Downloading and Installing Cactus Canyon Continued...

:: FILE LOCK FIX: Kill any rogue Python processes before modifying game folders
echo Checking for locked files and terminating background Python processes...
taskkill /F /IM python.exe /T >nul 2>nul
taskkill /F /IM pythonw.exe /T >nul 2>nul
timeout /T 2 /NOBREAK >nul

cd /d "%~dp0resources"

:: Ensure target directories exist before downloading into them
if not exist "%OUTDIR%\games\cactuscanyon\dmd\" mkdir "%OUTDIR%\games\cactuscanyon\dmd\"
if not exist "%OUTDIR%\games\cactuscanyon\sounds\" mkdir "%OUTDIR%\games\cactuscanyon\sounds\"

If Not Exist "%OUTDIR%\games\cactuscanyon\dmd\.DS_Store" (
    echo Downloading DMD assets...
    wget -q --no-check-certificate http://soldmy.org/pin/ccc/files/ccc_dmd_20190629.zip || call :fail "DMD Download failed."
    %ZIP_TOOL% x -y -bd ccc_dmd_20190629.zip -o"%OUTDIR%\games\cactuscanyon\" >nul
    DEL /F /Q ccc_dmd_20190629.zip >nul
)

If Not Exist "%OUTDIR%\games\cactuscanyon\sounds\.DS_Store" (
    echo Downloading Sounds...
    wget -q --no-check-certificate http://soldmy.org/pin/ccc/files/ccc_sounds_20190629.zip || call :fail "Sound Download failed."
    %ZIP_TOOL% x -y -bd ccc_sounds_20190629.zip -o"%OUTDIR%\games\cactuscanyon\" >nul
    DEL /F /Q ccc_sounds_20190629.zip >nul
)

echo Downloading Core Game Code...
wget -q -O CCCforVP.zip --no-check-certificate --content-disposition https://github.com/CarnyPriest/CCCforVP/archive/master.zip || call :fail "Code Download failed."

echo Upgrading Directories...
If Exist "%OUTDIR%\games\cactuscanyon\config\user_settings.yaml" move /Y "%OUTDIR%\games\cactuscanyon\config\user_settings.yaml" "%OUTDIR%\games" >nul
move /Y "%OUTDIR%\games\cactuscanyon\dmd" "%OUTDIR%\games" >nul 2>nul
move /Y "%OUTDIR%\games\cactuscanyon\sounds" "%OUTDIR%\games" >nul 2>nul
RD /S /Q "%OUTDIR%\games\cactuscanyon" >nul 2>nul
%ZIP_TOOL% x -y -bd CCCforVP.zip -o"%OUTDIR%\games\" >nul
ren "%OUTDIR%\games\CCCforVP-master" cactuscanyon
DEL /F /Q CCCforVP.zip >nul

If Exist "%OUTDIR%\games\user_settings.yaml" move /Y "%OUTDIR%\games\user_settings.yaml" "%OUTDIR%\games\cactuscanyon\config" >nul
move /Y "%OUTDIR%\games\dmd" "%OUTDIR%\games\cactuscanyon" >nul 2>nul
move /Y "%OUTDIR%\games\sounds" "%OUTDIR%\games\cactuscanyon" >nul 2>nul

If Not Exist "%OUTDIR%\games\cactuscanyon\sounds\music\yak_sax.wav" (
    echo Downloading Betty Quotes...
    wget -q --no-check-certificate --content-disposition https://www.dropbox.com/s/usrwv1szgbqxxt9/CCCforVPsoundsupdate20190629.zip?dl=0
    %ZIP_TOOL% x -y -bd CCCforVPsoundsupdate20190629.zip -o"%OUTDIR%\games\cactuscanyon\" >nul
    DEL /F /Q CCCforVPsoundsupdate20190629.zip >nul
)

:: -----------------------------------------------------------------------------
:: 6. VPX Bridge & Cleanup
:: -----------------------------------------------------------------------------
echo.
echo [4/4] Finalizing and Securing Visual Pinball X Bridge...

echo Registering VPCOM explicitly to Python 2.7...
"%PY_DIR%\python.exe" "%OUTDIR%\tools\register_vpcom.py" --register >nul 2>&1

echo Injecting Safe P-ROC DLL paths to Windows...
powershell -Command "$p = [Environment]::GetEnvironmentVariable('Path', 'Machine'); if ($p -notmatch '%TARGET_DRIVE%:\\MinGW\\bin') { $p += ';%TARGET_DRIVE%:\MinGW\bin;%TARGET_DRIVE%:\P-ROC\cmake\bin'; [Environment]::SetEnvironmentVariable('Path', $p, 'Machine') }"

:: FILE LOCK FIX: Final sweep for locked processes before deleting temp folders
taskkill /F /IM python.exe /T >nul 2>nul
taskkill /F /IM pythonw.exe /T >nul 2>nul

md "%APPDATA%\Microsoft\Windows\Start Menu\Programs\P-ROC Software\" 2>nul
xcopy /B /Y "%OUTDIR%\P-ROC Software.url" "%APPDATA%\Microsoft\Windows\Start Menu\Programs\P-ROC Software\" >nul 2>nul

reg add %UNINST_KEY%\P-ROC /f >nul
reg add %UNINST_KEY%\P-ROC /v DisplayName /t REG_SZ /d "P-ROC Environment 1.27.03" /f >nul
reg add %UNINST_KEY%\P-ROC /v DisplayVersion /t REG_SZ /d "1.27.03" /f >nul
reg add %UNINST_KEY%\P-ROC /v Publisher /t REG_SZ /d "pinballcontrollers.com" /f >nul
reg add %UNINST_KEY%\P-ROC /v URLInfoAbout /t REG_SZ /d "http://www.pinballcontrollers.com/" /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PYSDL2_DLL_PATH /t REG_EXPAND_SZ /d "%OUTDIR%\DLLs\" /f >nul

RD /S /Q "%OUTDIR%\$WINDIR" >nul 2>nul
RD /S /Q "%OUTDIR%\$USERDIR" >nul 2>nul
RD /S /Q "%OUTDIR%\ftdi\" >nul 2>nul
RD /S /Q "%OUTDIR%\scripts\" >nul 2>nul
RD /S /Q "%OUTDIR%\tmp" >nul 2>nul
RD /S /Q "%OUTDIR%\pypinproc" >nul 2>nul
RD /S /Q "%OUTDIR%\pyprocgame" >nul 2>nul
RD /S /Q "%OUTDIR%\libpinproc" >nul 2>nul
RD /S /Q "%OUTDIR%\yaml-cpp-0.2.5" >nul 2>nul

:: -----------------------------------------------------------------------------
:: 7. Creating Helper Scripts
:: -----------------------------------------------------------------------------
echo Generating Test CCC.bat Launcher...
if exist "%OUTDIR%\Test CCC.bat" del "%OUTDIR%\Test CCC.bat"
(
echo @echo off
echo setlocal
echo TITLE Test Cactus Canyon Continued
echo echo Loading Python 2.7 Environment for Testing...
echo SET "PATH=%MINGW_DIR%\bin;%OUTDIR%\cmake\bin;%PY_DIR%\Scripts;%PY_DIR%;%%PATH%%"
echo cd /d "%OUTDIR%\games\cactuscanyon"
echo echo.
echo echo Launching CCC...
echo "%PY_DIR%\python.exe" game.py
echo echo.
echo pause
) > "%OUTDIR%\Test CCC.bat"

echo Generating Custom Uninstaller...
set "UNINSTALLER=%~dp0Uninstall_PROC.bat"
if exist "%UNINSTALLER%" del "%UNINSTALLER%"
echo @echo off>> "%UNINSTALLER%"
echo setlocal>> "%UNINSTALLER%"
echo TITLE P-ROC and CCC Uninstaller>> "%UNINSTALLER%"
echo ^>nul 2^>^&1 "%%SYSTEMROOT%%\system32\cacls.exe" "%%SYSTEMROOT%%\system32\config\system">> "%UNINSTALLER%"
echo if '%%errorlevel%%' NEQ '0' (>> "%UNINSTALLER%"
echo     echo Requesting administrative privileges...>> "%UNINSTALLER%"
echo     goto UACPrompt>> "%UNINSTALLER%"
echo ) else ( goto gotAdmin )>> "%UNINSTALLER%"
echo :UACPrompt>> "%UNINSTALLER%"
echo     echo Set UAC = CreateObject^("Shell.Application"^) ^> "%%temp%%\getadmin.vbs">> "%UNINSTALLER%"
echo     echo UAC.ShellExecute "%%~s0", "", "", "runas", 1 ^>^> "%%temp%%\getadmin.vbs">> "%UNINSTALLER%"
echo     cscript //NoLogo "%%temp%%\getadmin.vbs">> "%UNINSTALLER%"
echo     exit /B>> "%UNINSTALLER%"
echo :gotAdmin>> "%UNINSTALLER%"
echo     if exist "%%temp%%\getadmin.vbs" ( del "%%temp%%\getadmin.vbs" )>> "%UNINSTALLER%"
echo     pushd "%%CD%%">> "%UNINSTALLER%"
echo     CD /D "%%~dp0">> "%UNINSTALLER%"
echo echo ===================================================>> "%UNINSTALLER%"
echo echo   Uninstalling P-ROC, CCC, and Dependencies>> "%UNINSTALLER%"
echo echo ===================================================>> "%UNINSTALLER%"
echo echo.>> "%UNINSTALLER%"
echo echo WARNING: This will remove %OUTDIR%, %MINGW_DIR%, %PY_DIR%,>> "%UNINSTALLER%"
echo echo and associated registry keys.>> "%UNINSTALLER%"
echo echo.>> "%UNINSTALLER%"
echo pause>> "%UNINSTALLER%"
echo echo [1/4] Deleting Directories...>> "%UNINSTALLER%"
echo IF EXIST "%OUTDIR%" RD /S /Q "%OUTDIR%">> "%UNINSTALLER%"
echo IF EXIST "%MINGW_DIR%" RD /S /Q "%MINGW_DIR%">> "%UNINSTALLER%"
echo IF EXIST "%%USERPROFILE%%\.pyprocgame" RD /S /Q "%%USERPROFILE%%\.pyprocgame">> "%UNINSTALLER%"
echo echo [2/4] Removing Start Menu Shortcuts...>> "%UNINSTALLER%"
echo IF EXIST "%%APPDATA%%\Microsoft\Windows\Start Menu\Programs\P-ROC Software" (>> "%UNINSTALLER%"
echo     RD /S /Q "%%APPDATA%%\Microsoft\Windows\Start Menu\Programs\P-ROC Software">> "%UNINSTALLER%"
echo )>> "%UNINSTALLER%"
echo echo [3/4] Cleaning Registry and Machine PATH...>> "%UNINSTALLER%"
echo reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\P-ROC" /f ^>nul 2^>nul>> "%UNINSTALLER%"
echo reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PYSDL2_DLL_PATH /f ^>nul 2^>nul>> "%UNINSTALLER%"
echo powershell -Command "$p = [Environment]::GetEnvironmentVariable('Path', 'Machine'); $p = $p.Replace(';%TARGET_DRIVE%:\MinGW\bin;%TARGET_DRIVE%:\P-ROC\cmake\bin', ''); [Environment]::SetEnvironmentVariable('Path', $p, 'Machine')">> "%UNINSTALLER%"
echo echo [4/4] Uninstalling Python 2.7...>> "%UNINSTALLER%"
echo msiexec /x {9DA28CE5-0AA5-429E-86D8-686ED898C665} /qn>> "%UNINSTALLER%"
echo echo ===================================================>> "%UNINSTALLER%"
echo echo UNINSTALLATION COMPLETE.>> "%UNINSTALLER%"
echo echo ===================================================>> "%UNINSTALLER%"
echo pause>> "%UNINSTALLER%"
echo exit /B 0>> "%UNINSTALLER%"

:: -----------------------------------------------------------------------------
:: 8. Verification
:: -----------------------------------------------------------------------------
echo Checking installation integrity...
echo import pinproc > "%OUTDIR%\testPROC.py"
echo import procgame >> "%OUTDIR%\testPROC.py"
echo print("P-ROC verification passed!") >> "%OUTDIR%\testPROC.py"

"%PY_DIR%\python.exe" "%OUTDIR%\testPROC.py" >nul || call :fail "Installation verification failed. Modules did not load."
del /Q "%OUTDIR%\testPROC.py"

echo ===================================================
echo INSTALLATION COMPLETE! P-ROC and CCC are ready on %TARGET_DRIVE%:\.
echo - A 'Test CCC.bat' launcher has been created in %OUTDIR%\
echo - An 'Uninstall_PROC.bat' has been created in this folder.
echo ===================================================
echo.
echo NOTE: You must restart your computer before launching VPX 
echo so the system can recognize the new P-ROC Bridge pathways!
echo.
echo Closing automatically in 15 seconds...
timeout /T 15
exit /B 0

:: -----------------------------------------------------------------------------
:: Error Handling Subroutine
:: -----------------------------------------------------------------------------
:fail
echo.
echo ERROR: %~1
echo Exiting installation...
pause
exit /B 1