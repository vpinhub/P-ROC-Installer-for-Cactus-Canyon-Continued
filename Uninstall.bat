@echo off
setlocal EnableDelayedExpansion

TITLE P-ROC and CCC Uninstaller

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

echo ===================================================
echo   Uninstalling P-ROC, CCC, and Dependencies
echo ===================================================
echo.

:: -----------------------------------------------------------------------------
:: 2. Auto-Detect Target Drive
:: -----------------------------------------------------------------------------
echo Scanning system for P-ROC installation...
set "TARGET_DRIVE="

:: Loop through all possible drive letters to find the P-ROC folder
for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%D:\P-ROC\games\cactuscanyon" (
        set TARGET_DRIVE=%%D
        goto :foundDrive
    )
)

:foundDrive
if "%TARGET_DRIVE%"=="" (
    echo [!] Could not automatically locate the P-ROC installation.
    set /p TARGET_DRIVE="Please enter the drive letter manually (e.g., C, D, E): "
    :: Strip extra characters if the user types "D:" instead of "D"
    set TARGET_DRIVE=!TARGET_DRIVE:~0,1!
) else (
    echo [OK] Found P-ROC installation on Drive %TARGET_DRIVE%:.
)

SET OUTDIR=%TARGET_DRIVE%:\P-ROC
SET MINGW_DIR=%TARGET_DRIVE%:\MinGW
SET PY_DIR=%TARGET_DRIVE%:\Python27

echo.
echo WARNING: This will completely remove:
echo - %OUTDIR%
echo - %MINGW_DIR%
echo - %PY_DIR%
echo - All associated registry keys and Start Menu shortcuts.
echo.
pause

:: -----------------------------------------------------------------------------
:: 3. Removal Process
:: -----------------------------------------------------------------------------
echo.
echo [1/4] Deleting Directories...
IF EXIST "%OUTDIR%" RD /S /Q "%OUTDIR%"
IF EXIST "%MINGW_DIR%" RD /S /Q "%MINGW_DIR%"
IF EXIST "%USERPROFILE%\.pyprocgame" RD /S /Q "%USERPROFILE%\.pyprocgame"

echo [2/4] Removing Start Menu Shortcuts...
IF EXIST "%APPDATA%\Microsoft\Windows\Start Menu\Programs\P-ROC Software" (
    RD /S /Q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\P-ROC Software"
)

echo [3/4] Cleaning Registry and Machine PATH...
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\P-ROC" /f >nul 2>nul
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PYSDL2_DLL_PATH /f >nul 2>nul
powershell -Command "$p = [Environment]::GetEnvironmentVariable('Path', 'Machine'); if ($p) { $p = $p.Replace(';%TARGET_DRIVE%:\MinGW\bin;%TARGET_DRIVE%:\P-ROC\cmake\bin', ''); [Environment]::SetEnvironmentVariable('Path', $p, 'Machine') }"

echo [4/4] Uninstalling Python 2.7...
msiexec /x {9DA28CE5-0AA5-429E-86D8-686ED898C665} /qn 

echo ===================================================
echo UNINSTALLATION COMPLETE.
echo ===================================================
pause
exit /B 0