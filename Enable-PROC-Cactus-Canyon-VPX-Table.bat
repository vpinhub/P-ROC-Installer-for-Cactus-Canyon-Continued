@echo off
setlocal EnableDelayedExpansion

TITLE Patch Cactus Canyon VPX for P-ROC

echo ===================================================
echo   Cactus Canyon VPX Table Patcher for P-ROC
echo ===================================================
echo.

set "VPXTOOL=%~dp0resources\vpxtool.exe"
if not exist "!VPXTOOL!" (
    echo ERROR: vpxtool.exe not found at:
    echo   !VPXTOOL!
    pause & exit /b 1
)

:: ─────────────────────────────────────────────────────────────
:: STEP 1: LOCATE VISUAL PINBALL TABLES FOLDER
:: ─────────────────────────────────────────────────────────────
set "TABLES_DIR="
echo Searching for Visual Pinball tables folder...
for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if not defined TABLES_DIR if exist "%%D:\vPinball\VisualPinball\Tables\" set "TABLES_DIR=%%D:\vPinball\VisualPinball\Tables"
    if not defined TABLES_DIR if exist "%%D:\Visual Pinball\Tables\"         set "TABLES_DIR=%%D:\Visual Pinball\Tables"
    if not defined TABLES_DIR if exist "%%D:\VisualPinball\Tables\"          set "TABLES_DIR=%%D:\VisualPinball\Tables"
)

if defined TABLES_DIR (
    echo   Found: !TABLES_DIR!
) else (
    echo   Tables folder not found automatically.
    echo.
    set /p "TABLES_DIR=Enter full path to your VPX Tables folder: "
    if not defined TABLES_DIR ( echo ERROR: No path entered. & pause & exit /b 1 )
    if "!TABLES_DIR:~-1!"=="\" set "TABLES_DIR=!TABLES_DIR:~0,-1!"
    if not exist "!TABLES_DIR!\" (
        echo ERROR: Folder not found: !TABLES_DIR!
        pause & exit /b 1
    )
)

:: ─────────────────────────────────────────────────────────────
:: STEP 2: LOCATE SOURCE VPX FILE
:: ─────────────────────────────────────────────────────────────
echo.
echo Searching for Cactus Canyon (Bally 1998) table...
set "SOURCE_VPX="
set "FIND_PS1=%TEMP%\find_cc_vpx.ps1"

echo $d = '!TABLES_DIR!' > "!FIND_PS1!"
echo $f = Get-ChildItem $d -Filter '*Cactus Canyon*Bally 1998*.vpx' -ErrorAction SilentlyContinue ^| Where-Object { $_.Name -notmatch 'Continued' } ^| Select-Object -First 1 >> "!FIND_PS1!"
echo if ($f) { Write-Output $f.FullName } >> "!FIND_PS1!"

for /f "usebackq delims=" %%F in (`powershell -NoProfile -ExecutionPolicy Bypass -File "!FIND_PS1!"`) do set "SOURCE_VPX=%%F"
del "!FIND_PS1!" 2>nul

if defined SOURCE_VPX (
    echo   Found: !SOURCE_VPX!
) else (
    echo   Not found automatically in !TABLES_DIR!
    echo.
    set /p "SOURCE_VPX=Enter full path to your Cactus Canyon .vpx file: "
    if not defined SOURCE_VPX ( echo ERROR: No path entered. & pause & exit /b 1 )
    if not exist "!SOURCE_VPX!" (
        echo ERROR: File not found: !SOURCE_VPX!
        pause & exit /b 1
    )
)

:: ─────────────────────────────────────────────────────────────
:: STEP 3: DETERMINE COPY NAME
:: ─────────────────────────────────────────────────────────────
for %%F in ("!SOURCE_VPX!") do set "SOURCE_NAME=%%~nxF"

echo !SOURCE_NAME! | findstr /i "VPW" >nul
if not errorlevel 1 (
    set "DEST_NAME=Cactus Canyon Continued (Bally 1998) VPW 1.1.vpx"
) else (
    set "DEST_NAME=Cactus Canyon Continued (Bally 1998).vpx"
)

set "DEST_VPX=!TABLES_DIR!\!DEST_NAME!"

:: ─────────────────────────────────────────────────────────────
:: STEP 4: CHECK IF DESTINATION ALREADY EXISTS
:: ─────────────────────────────────────────────────────────────
if exist "!DEST_VPX!" (
    echo.
    echo WARNING: File already exists:
    echo   !DEST_VPX!
    echo.
    echo   [1] Overwrite it
    echo   [2] Enter a different filename
    echo.
    set /p "OW_CHOICE=Enter 1 or 2: "
    if "!OW_CHOICE!"=="2" (
        echo.
        set /p "DEST_NAME=Enter new filename (no path, include .vpx): "
        if not defined DEST_NAME ( echo ERROR: No name entered. & pause & exit /b 1 )
        set "DEST_VPX=!TABLES_DIR!\!DEST_NAME!"
    )
)

:: ─────────────────────────────────────────────────────────────
:: STEP 5: COPY VPX
:: ─────────────────────────────────────────────────────────────
echo.
echo Copying table...
echo   !SOURCE_VPX!
echo   -^> !DEST_VPX!
copy /y "!SOURCE_VPX!" "!DEST_VPX!" >nul
if errorlevel 1 (
    echo ERROR: Copy failed.
    pause & exit /b 1
)
echo   Done.

:: ─────────────────────────────────────────────────────────────
:: STEP 6: EXTRACT VBS FROM COPY
:: ─────────────────────────────────────────────────────────────
echo.
echo Extracting table script...
"!VPXTOOL!" extractvbs "!DEST_VPX!"
if errorlevel 1 (
    echo ERROR: vpxtool failed to extract the script.
    pause & exit /b 1
)

for %%F in ("!DEST_VPX!") do set "DEST_VBS=%%~dpnF.vbs"
if not exist "!DEST_VBS!" (
    echo ERROR: Extracted VBS not found at:
    echo   !DEST_VBS!
    pause & exit /b 1
)
echo   Extracted: !DEST_VBS!

:: ─────────────────────────────────────────────────────────────
:: STEP 7: PATCH VBS - SET PROC = 1
:: ─────────────────────────────────────────────────────────────
echo.
echo Patching script: setting PROC = 1...
set "VBS_PS1=%TEMP%\patch_vbs.ps1"

echo $f = '!DEST_VBS!' > "!VBS_PS1!"
echo $c = [IO.File]::ReadAllText($f) >> "!VBS_PS1!"
echo if ($c -notmatch '(?m)^\s*PROC\s*=\s*0') { Write-Host 'WARNING: PROC = 0 not found in script. Check the VBS manually.'; exit 0 } >> "!VBS_PS1!"
echo $c = $c -replace '(?m)^(\s*PROC\s*=\s*)0', '${1}1' >> "!VBS_PS1!"
echo [IO.File]::WriteAllText($f, $c) >> "!VBS_PS1!"
echo Write-Host '  PROC = 0 changed to PROC = 1.' >> "!VBS_PS1!"

powershell -NoProfile -ExecutionPolicy Bypass -File "!VBS_PS1!"
set PS_EXIT=!ERRORLEVEL!
del "!VBS_PS1!" 2>nul
if !PS_EXIT! neq 0 ( echo ERROR: Script patch failed. & pause & exit /b 1 )

:: ─────────────────────────────────────────────────────────────
:: STEP 8: IMPORT PATCHED VBS BACK INTO VPX
:: ─────────────────────────────────────────────────────────────
echo.
echo Importing patched script back into table...
"!VPXTOOL!" importvbs "!DEST_VPX!"
if errorlevel 1 (
    echo ERROR: vpxtool failed to import the script.
    pause & exit /b 1
)
echo   Done.

:: ─────────────────────────────────────────────────────────────
:: COMPLETE
:: ─────────────────────────────────────────────────────────────
echo.
echo ===================================================
echo   PATCH COMPLETE
echo ===================================================
echo   Source : !SOURCE_NAME!
echo   Created: !DEST_NAME!
echo   Script : PROC = 1 (P-ROC hardware enabled)
echo.
echo   The patched table is ready in:
echo   !TABLES_DIR!
echo.
echo ===================================================
echo   IMPORTANT - VPX VERSION
echo ===================================================
echo   Cactus Canyon Continued is currently only
echo   supported and tested on VPX 10.7.4
echo.
echo   For VPX 10.8 compatibility, check the installer
echo   page for optional instructions - proceed at your
echo   own risk as it is not officially supported.
echo ===================================================
echo.
pause
endlocal
