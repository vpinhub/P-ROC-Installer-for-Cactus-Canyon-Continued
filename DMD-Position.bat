@echo off
setlocal EnableDelayedExpansion

TITLE CCC DMD Setup Wizard

echo ===================================================
echo   Cactus Canyon Continued - DMD Setup Wizard
echo ===================================================
echo.

:: ─────────────────────────────────────────────────────────────
:: STEP 1: LOCATE P-ROC INSTALLATION
:: ─────────────────────────────────────────────────────────────
set "INSTALL_DIR="
echo Searching for P-ROC installation...
for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if not defined INSTALL_DIR (
        if exist "%%D:\P-ROC\games\cactuscanyon\ep\ep_desktop_pygame.py" (
            set "INSTALL_DIR=%%D:\P-ROC"
            echo   Found: %%D:\P-ROC
        )
    )
)

if not defined INSTALL_DIR (
    echo   Not found automatically.
    echo.
    set /p "INSTALL_DIR=Enter full path to P-ROC install (e.g. D:\P-ROC): "
    if not defined INSTALL_DIR ( echo ERROR: No path entered. & pause & exit /b 1 )
    if "!INSTALL_DIR:~-1!"=="\" set "INSTALL_DIR=!INSTALL_DIR:~0,-1!"
    if not exist "!INSTALL_DIR!\games\cactuscanyon\ep\ep_desktop_pygame.py" (
        echo.
        echo ERROR: P-ROC game files not found at: !INSTALL_DIR!
        pause & exit /b 1
    )
)

set "PROC_DRIVE=!INSTALL_DIR:~0,1!"
set "YAML_FILE=!INSTALL_DIR!\games\cactuscanyon\config\user_settings.yaml"

if not exist "!YAML_FILE!" (
    echo.
    echo ERROR: user_settings.yaml not found at:
    echo   !YAML_FILE!
    echo Please launch the game at least once to generate this file, then re-run.
    pause & exit /b 1
)
echo.

:: ─────────────────────────────────────────────────────────────
:: STEP 2: APPLY ALWAYS-ON-TOP PATCH (REQUIRED FOR BOTH MODES)
:: ─────────────────────────────────────────────────────────────
echo Applying always-on-top patch (required for all DMD modes)...
call :applyPatch
if errorlevel 1 ( pause & exit /b 1 )
echo.

:: ─────────────────────────────────────────────────────────────
:: STEP 3: CHOOSE MODE
:: ─────────────────────────────────────────────────────────────
echo ===================================================
echo   Choose your DMD display method:
echo ===================================================
echo.
echo   [1] Native Python Color DMD  ^<-- RECOMMENDED
echo.
echo       The game's own DMD window is placed directly on
echo       your screen or cabinet DMD monitor.
echo       This script patches the game to keep the DMD
echo       window on top of VPX and all other windows.
echo       Best colour accuracy and sharpest resolution.
echo       Ideal for desktop or cabinet with a dedicated
echo       DMD display.
echo.
echo   [2] Freezy DMDExt Mirror
echo.
echo       A tiny 128x32 pixel DMD window is placed in the
echo       bottom corner of your screen. DMDExt captures
echo       that area and mirrors it to your device.
echo       Best suited for PinDMD and ZeDMD hardware.
echo       Also supports a software virtual DMD via DMDExt.
echo.
echo       To add CCC to PinUp Popper, follow the wiki guide:
echo       Settings ^> Other Emulators  (search: PinUp Popper Wiki)
echo       Or use the generated Launch_CCC_Freezy.bat directly.
echo.
set /p "CHOICE=Enter 1 or 2: "
if "!CHOICE!"=="1" goto nativeSetup
if "!CHOICE!"=="2" goto freezySetup
echo Invalid choice.
pause & exit /b 1


:: =============================================================
:: NATIVE MODE
:: =============================================================
:nativeSetup
echo.
echo ===================================================
echo   Native Python Color DMD Setup
echo ===================================================
echo.
echo   Pixel size controls how large each DMD dot appears.
echo.
echo     4   ^<-- recommended for a single desktop monitor
echo     8   ^<-- recommended for a cabinet DMD panel
echo    10   ^<-- larger cabinet DMD panel
echo    12   ^<-- extra large cabinet DMD panel
echo.
set /p "PIXEL_SIZE=Enter pixel size [press Enter for 4]: "
if "!PIXEL_SIZE!"=="" set "PIXEL_SIZE=4"

:: ── Find dmddevice.ini ──────────────────────────────────────
echo.
echo Searching for dmddevice.ini...
set "INI_FILE="
for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if not defined INI_FILE if exist "%%D:\vpinball\visualpinball\vpinmame\dmddevice.ini"  set "INI_FILE=%%D:\vpinball\visualpinball\vpinmame\dmddevice.ini"
    if not defined INI_FILE if exist "%%D:\vPinball\VisualPinball\VPinMAME\dmddevice.ini"  set "INI_FILE=%%D:\vPinball\VisualPinball\VPinMAME\dmddevice.ini"
    if not defined INI_FILE if exist "%%D:\Visual Pinball\VPinMAME\dmddevice.ini"          set "INI_FILE=%%D:\Visual Pinball\VPinMAME\dmddevice.ini"
    if not defined INI_FILE if exist "%%D:\VPinMAME\dmddevice.ini"                         set "INI_FILE=%%D:\VPinMAME\dmddevice.ini"
)

set "DMD_LEFT=0"
set "DMD_TOP=0"
set "COORDS_SOURCE=default (0,0 - no ini found)"

if defined INI_FILE (
    echo   Found: !INI_FILE!
    echo   Reading [cc_13] Cactus Canyon coordinates...
    call :readIniCoords "!INI_FILE!" cc_13
    if "!DMD_LEFT!"=="0" if "!DMD_TOP!"=="0" (
        echo   Note: [cc_13] not found in ini - using 0,0.
        set "COORDS_SOURCE=default - [cc_13] not in ini"
    ) else (
        set "COORDS_SOURCE=dmddevice.ini [cc_13]"
        echo   Coordinates: X=!DMD_LEFT!  Y=!DMD_TOP!
    )
) else (
    echo   Not found automatically.
    echo.
    set /p "INI_MANUAL=Enter full path to dmddevice.ini (or press Enter to enter coords manually): "
    if defined INI_MANUAL (
        if exist "!INI_MANUAL!" (
            set "INI_FILE=!INI_MANUAL!"
            call :readIniCoords "!INI_MANUAL!" cc_13
            if not "!DMD_LEFT!"=="0" (
                set "COORDS_SOURCE=dmddevice.ini [cc_13]"
                echo   Coordinates: X=!DMD_LEFT!  Y=!DMD_TOP!
            ) else (
                echo   [cc_13] not found - enter coordinates below.
            )
        ) else (
            echo   File not found at that path.
        )
    )
)

:: ── Confirm or override coordinates ────────────────────────
echo.
echo   DMD position: X=!DMD_LEFT!  Y=!DMD_TOP!  (source: !COORDS_SOURCE!)
echo.
set /p "OVERRIDE=Use different coordinates? (Y/N) [N]: "
if /I "!OVERRIDE!"=="Y" (
    set /p "DMD_LEFT=  Enter X position (Left): "
    set /p "DMD_TOP=  Enter Y position (Top):  "
)

:: ── Write yaml ──────────────────────────────────────────────
echo.
echo Updating user_settings.yaml...
call :updateYaml "!YAML_FILE!" !PIXEL_SIZE! !DMD_LEFT! !DMD_TOP! ROUND
if errorlevel 1 ( echo ERROR: Failed to update yaml. & pause & exit /b 1 )

echo.
echo ===================================================
echo   SETUP COMPLETE - Native Mode
echo ===================================================
echo   Pixel Size  : !PIXEL_SIZE!
echo   X Position  : !DMD_LEFT!
echo   Y Position  : !DMD_TOP!
echo   Dot Style   : ROUND
echo   Always-on-Top patch: Applied
echo ===================================================
echo.
call :testPrompt
exit /b 0


:: =============================================================
:: FREEZY DMDEXT MIRROR MODE
:: =============================================================
:freezySetup
echo.
echo ===================================================
echo   Freezy DMDExt Mirror Setup
echo ===================================================
echo.

:: ── Find dmdext.exe ─────────────────────────────────────────
set "DMDEXT="
echo Searching for dmdext.exe...
for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if not defined DMDEXT if exist "%%D:\vpinball\visualpinball\vpinmame\dmdext.exe"  set "DMDEXT=%%D:\vpinball\visualpinball\vpinmame\dmdext.exe"
    if not defined DMDEXT if exist "%%D:\vPinball\VisualPinball\VPinMAME\dmdext.exe"  set "DMDEXT=%%D:\vPinball\VisualPinball\VPinMAME\dmdext.exe"
    if not defined DMDEXT if exist "%%D:\Visual Pinball\VPinMAME\dmdext.exe"          set "DMDEXT=%%D:\Visual Pinball\VPinMAME\dmdext.exe"
    if not defined DMDEXT if exist "%%D:\VPinMAME\dmdext.exe"                         set "DMDEXT=%%D:\VPinMAME\dmdext.exe"
)

if defined DMDEXT (
    echo   Found: !DMDEXT!
) else (
    echo   dmdext.exe not found automatically.
    echo.
    set /p "DMDEXT=Enter full path to dmdext.exe (or press Enter to use placeholder): "
    if not defined DMDEXT (
        echo   WARNING: Using placeholder path - edit the launcher before use.
        set "DMDEXT=C:\vPinball\VisualPinball\VPinMAME\dmdext.exe"
    ) else (
        if not exist "!DMDEXT!" echo   WARNING: File not found at that path.
    )
)

:: ── Choose output device ────────────────────────────────────
echo.
echo   Where should DMDExt send the DMD output?
echo.
echo   [1] Virtual DMD  (software overlay window on screen)
echo   [2] PinDMD v3    (serial hardware device)
echo   [3] PinDMD v2    (serial hardware device)
echo   [4] PinDMD v1    (serial hardware device)
echo   [5] ZeDMD        (USB hardware device)
echo   [6] Custom       (enter dmdext parameters manually)
echo.
set /p "DEVICE=Enter 1-6 [press Enter for 1]: "
if "!DEVICE!"=="" set "DEVICE=1"

set "DMDEXT_DEST=--destination virtual --virtual-stay-on-top"
set "DEVICE_LABEL=Virtual DMD overlay"

if "!DEVICE!"=="2" (
    set /p "COM_PORT=  Enter COM port for PinDMD v3 (e.g. COM5): "
    set "DMDEXT_DEST=--destination pindmdv3 --port !COM_PORT!"
    set "DEVICE_LABEL=PinDMD v3 on !COM_PORT!"
)
if "!DEVICE!"=="3" (
    set /p "COM_PORT=  Enter COM port for PinDMD v2 (e.g. COM4): "
    set "DMDEXT_DEST=--destination pindmdv2 --port !COM_PORT!"
    set "DEVICE_LABEL=PinDMD v2 on !COM_PORT!"
)
if "!DEVICE!"=="4" (
    set /p "COM_PORT=  Enter COM port for PinDMD v1 (e.g. COM3): "
    set "DMDEXT_DEST=--destination pindmdv1 --port !COM_PORT!"
    set "DEVICE_LABEL=PinDMD v1 on !COM_PORT!"
)
if "!DEVICE!"=="5" (
    set "DMDEXT_DEST=--destination zedmd"
    set "DEVICE_LABEL=ZeDMD"
)
if "!DEVICE!"=="6" (
    set /p "DMDEXT_DEST=  Enter custom dmdext destination parameters: "
    set "DEVICE_LABEL=Custom"
)

:: ── Place native window as tiny 128x32 capture target ───────
echo.
echo   The native DMD window will be set to pixel size 1 (128x32 pixels).
echo   DMDExt captures that exact area of your screen.
echo   Bottom-left is recommended - out of the way of the playfield.
echo.
echo   Where should the tiny capture window sit?
echo.
echo   [1] Bottom-left  (0, [screen height - 32])  ^<-- RECOMMENDED
echo   [2] Top-left     (0, 0)
echo   [3] Custom       (enter X and Y manually)
echo.
set /p "CORNER=Enter 1-3 [press Enter for 1]: "
if "!CORNER!"=="" set "CORNER=1"

set "CAP_X=0"
set "CAP_Y=0"

if "!CORNER!"=="1" (
    set /p "SCREEN_H=  Enter your screen height in pixels (e.g. 1080): "
    set /a "CAP_Y=!SCREEN_H! - 32"
)
if "!CORNER!"=="3" (
    set /p "CAP_X=  Enter X position: "
    set /p "CAP_Y=  Enter Y position: "
)

echo.
echo Configuring native DMD window as tiny capture target at (!CAP_X!, !CAP_Y!)...
call :updateYaml "!YAML_FILE!" 1 !CAP_X! !CAP_Y! SQUARE
if errorlevel 1 ( echo ERROR: Failed to update yaml. & pause & exit /b 1 )

:: ── Generate launcher (written to both P-ROC folder and installer folder)
set "LAUNCHER=!INSTALL_DIR!\Launch_CCC_Freezy.bat"
set "LAUNCHER_HERE=%~dp0Launch_CCC_Freezy.bat"
(
echo @echo off
echo :: Start dmdext - captures the tiny 128x32 native window on screen
echo start /min "" "!DMDEXT!" mirror --source screen --position !CAP_X! !CAP_Y! 128 32 !DMDEXT_DEST!
) > "!LAUNCHER!"
copy /y "!LAUNCHER!" "!LAUNCHER_HERE!" >nul

:: ── Generate standalone kill script for frontends ───────────
set "KILLER=!INSTALL_DIR!\Kill_DMDExt.bat"
(
echo @echo off
echo echo Stopping DMDExt...
echo taskkill /F /IM dmdext.exe ^>nul 2^>^&1
) > "!KILLER!"

echo.
echo ===================================================
echo   SETUP COMPLETE - Freezy DMDExt Mode
echo ===================================================
echo   Device      : !DEVICE_LABEL!
echo   Capture window: !CAP_X!, !CAP_Y! (128x32 px, visible but tiny)
echo   Dot Style   : SQUARE (optimal for capture)
echo   Pixel Size  : 1
echo   Always-on-Top patch: Applied
echo.
echo   Files created:
echo     !LAUNCHER!
echo     !LAUNCHER_HERE!
echo     !KILLER!
echo.
echo   HOW TO USE:
echo   Run Launch_CCC_Freezy.bat and waits for game to start.
echo   DMDExt starts first, when vpx starts the game CCC loads automatically.
echo.
echo   FRONTEND (PinballX / Pinup Popper):
echo   Launch_CCC_Freezy.bat shows cmd arugments for launch script.
echo   Check PinUp Popper Wiki for how to add to  PinUp Popper
echo   Visit: https://www.nailbuster.com/wikipinup/doku.php?id=emulator_other
echo ===================================================
echo.
call :testPrompt
exit /b 0


:: =============================================================
:: SUBROUTINE: Offer to launch Test CCC.bat
:: =============================================================
:testPrompt
set "TEST_BAT=!INSTALL_DIR!\Test CCC.bat"
if not exist "!TEST_BAT!" (
    echo NOTE: Test CCC.bat not found at !INSTALL_DIR! - skipping test option.
    echo.
    pause
    exit /b 0
)
echo Would you like to launch a test run now to check the DMD position?
echo This will start Cactus Canyon Continued via Test CCC.bat.
echo Close the game window when done to return here.
echo.
set /p "RUN_TEST=Launch test? (Y/N) [N]: "
if /I "!RUN_TEST!"=="Y" (
    echo.
    echo Launching test - close the game when you are done...
    call "!TEST_BAT!"
    echo.
    echo Test closed. If the DMD position was wrong, re-run this wizard.
)
echo.
pause
exit /b 0


:: =============================================================
:: SUBROUTINE: Apply always-on-top patch
:: =============================================================
:applyPatch
set "APT_TARGET=!INSTALL_DIR!\games\cactuscanyon\ep\ep_desktop_pygame.py"
set "APT_BACKUP=!APT_TARGET!.bak"
set "APT_PS1=%TEMP%\dmd_topmost.ps1"

if not exist "!APT_BACKUP!" (
    copy "!APT_TARGET!" "!APT_BACKUP!" >nul 2>&1
    if errorlevel 1 ( echo   ERROR: Could not create backup. & exit /b 1 )
    echo   Backup created: !APT_BACKUP!
) else (
    echo   Backup already exists - original preserved.
)

echo $f = '!APT_TARGET!' > "!APT_PS1!"
echo $c = [IO.File]::ReadAllText($f) >> "!APT_PS1!"
echo if ($c.Contains('Keep DMD window always on top')) { Write-Host '  Already patched.'; exit 0 } >> "!APT_PS1!"
echo $old = "        pygame.display.set_caption('Cactus Canyon Continued')" >> "!APT_PS1!"
echo $new = $old + "`n        # Keep DMD window always on top of other windows (e.g. VPX table)`n        try:`n            hwnd = pygame.display.get_wm_info()['window']`n            ctypes.windll.user32.SetWindowPos(hwnd, -1, 0, 0, 0, 0, 0x0003)`n        except Exception:`n            pass" >> "!APT_PS1!"
echo if (-not $c.Contains($old)) { Write-Host '  ERROR: Patch target line not found. File may be a different version.'; exit 1 } >> "!APT_PS1!"
echo [IO.File]::WriteAllText($f, $c.Replace($old, $new)) >> "!APT_PS1!"
echo Write-Host '  Patch applied.' >> "!APT_PS1!"

powershell -NoProfile -ExecutionPolicy Bypass -File "!APT_PS1!"
set APT_EXIT=!ERRORLEVEL!
del "!APT_PS1!" 2>nul
exit /b !APT_EXIT!


:: =============================================================
:: SUBROUTINE: Read virtualdmd left/top from an ini section
::   call :readIniCoords "path\to\file.ini" sectionname
::   Sets DMD_LEFT and DMD_TOP
:: =============================================================
:readIniCoords
set "RIC_FILE=%~1"
set "RIC_SECT=%~2"
set "RIC_PS1=%TEMP%\read_ini_coords.ps1"
set "DMD_LEFT=0"
set "DMD_TOP=0"

echo $inSect=$false; $left=0; $top=0 > "!RIC_PS1!"
echo Get-Content '!RIC_FILE!' ^| ForEach-Object { >> "!RIC_PS1!"
echo     if     ($_ -match '^\[!RIC_SECT!\]')                               { $inSect=$true  } >> "!RIC_PS1!"
echo     elseif ($_ -match '^\[')                                            { $inSect=$false } >> "!RIC_PS1!"
echo     elseif ($inSect -and $_ -match '^virtualdmd left\s*=\s*([-0-9]+)') { $left=$matches[1] } >> "!RIC_PS1!"
echo     elseif ($inSect -and $_ -match '^virtualdmd top\s*=\s*([-0-9]+)')  { $top=$matches[1]  } >> "!RIC_PS1!"
echo } >> "!RIC_PS1!"
echo Write-Output "$left $top" >> "!RIC_PS1!"

for /f "tokens=1,2" %%A in ('powershell -NoProfile -ExecutionPolicy Bypass -File "!RIC_PS1!"') do (
    set "DMD_LEFT=%%A"
    set "DMD_TOP=%%B"
)
del "!RIC_PS1!" 2>nul
exit /b 0


:: =============================================================
:: SUBROUTINE: Update user_settings.yaml
::   call :updateYaml "path" pixelsize x y dotstyle
:: =============================================================
:updateYaml
set "UY_FILE=%~1"
set "UY_PIX=%~2"
set "UY_X=%~3"
set "UY_Y=%~4"
set "UY_STYLE=%~5"
set "UY_PS1=%TEMP%\update_yaml.ps1"

echo $f = '!UY_FILE!' > "!UY_PS1!"
echo $c = [IO.File]::ReadAllText($f) >> "!UY_PS1!"
echo $c = $c -replace 'Color Display Pixel Size:\s*[0-9]+',  'Color Display Pixel Size: !UY_PIX!' >> "!UY_PS1!"
echo $c = $c -replace 'Color Display X Offset:\s*[-0-9]+',   'Color Display X Offset: !UY_X!' >> "!UY_PS1!"
echo $c = $c -replace 'Color Display Y Offset:\s*[-0-9]+',   'Color Display Y Offset: !UY_Y!' >> "!UY_PS1!"
echo $c = $c -replace 'Color Display Dot Style:\s*\w+',      'Color Display Dot Style: !UY_STYLE!' >> "!UY_PS1!"
echo [IO.File]::WriteAllText($f, $c) >> "!UY_PS1!"
echo Write-Host '  user_settings.yaml updated.' >> "!UY_PS1!"

powershell -NoProfile -ExecutionPolicy Bypass -File "!UY_PS1!"
set UY_EXIT=!ERRORLEVEL!
del "!UY_PS1!" 2>nul
exit /b !UY_EXIT!
