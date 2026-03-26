@echo off
setlocal EnableDelayedExpansion

TITLE VPX to P-ROC Bridge Fix

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

echo ===================================================
echo   Linking Visual Pinball X to P-ROC...
echo ===================================================
echo.

:: -----------------------------------------------------------------------------
:: Auto-Detect Target Drive
:: -----------------------------------------------------------------------------
echo Scanning system for P-ROC installation...
set "TARGET_DRIVE="

for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%D:\P-ROC\tools\register_vpcom.py" (
        set TARGET_DRIVE=%%D
        goto foundDrive
    )
)

:foundDrive
if "%TARGET_DRIVE%"=="" (
    echo [!] Could not automatically locate the P-ROC installation.
    set /p TARGET_DRIVE="Enter the drive letter where you installed P-ROC (e.g., C, D): "
    set TARGET_DRIVE=!TARGET_DRIVE:~0,1!
) else (
    echo [OK] Found P-ROC installation on Drive %TARGET_DRIVE%:
)

echo.
echo [1/2] Re-registering the COM Bridge explicitly to Python 2.7...
"%TARGET_DRIVE%:\Python27\python.exe" "%TARGET_DRIVE%:\P-ROC\tools\register_vpcom.py" --register

echo.
echo [2/2] Injecting Safe P-ROC DLL paths to Windows...
:: This adds MinGW and cmake to the path, but purposely leaves Python 2.7 OUT of it.
powershell -Command "$p = [Environment]::GetEnvironmentVariable('Path', 'Machine'); if ($p -notmatch '%TARGET_DRIVE%:\\MinGW\\bin') { $p += ';%TARGET_DRIVE%:\MinGW\bin;%TARGET_DRIVE%:\P-ROC\cmake\bin'; [Environment]::SetEnvironmentVariable('Path', $p, 'Machine') }"

echo.
echo ===================================================
echo BRIDGE SECURED!
echo ===================================================
echo.
echo IMPORTANT: You MUST completely close Visual Pinball X 
echo and restart your computer for Windows to broadcast the 
echo new DLL pathways to your applications.
echo.
pause
exit /B 0