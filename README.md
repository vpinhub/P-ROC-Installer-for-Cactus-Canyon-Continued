# 🌵 P-ROC Installer for Cactus Canyon Continued
### *Updated for 2026*

A Windows installer and configuration toolkit for running **Cactus Canyon Continued (CCC)** alongside **Visual Pinball X (VPX)**

> [!TIP]
> **How it works:** CCC runs entirely in software on the same PC as VPX. The P-ROC Python framework communicates with VPX via a COM bridge. VPX handles the playfield physics and rendering while the P-ROC layer provides the full Cactus Canyon Continued game logic, rules, and scoring engine. The virtual DMD is rendered by P-ROC's own Python window.

> [!NOTE]
> Throughout this guide, **`X:`** refers to the drive letter you choose during installation — for example `C:`, `D:`, or `E:`. P-ROC always installs to the root of that drive as `X:\P-ROC`.

---

## ⚡ Requirements

- **OS:** Windows 10 / 11 (64-bit) + Administrator rights
- **Engine:** [Visual Pinball X 10.7.4](#%EF%B8%8F-vpx-version-note) *(10.8 is experimental)*
- **Table:** `Cactus Canyon (Bally 1998) VPW 1.1.vpx` — [download from VPUniverse](https://vpuniverse.com/files/file/6267-cactus-canyon-continued-bally-1998-vpw-mod/)
- **Internet:** Required during installation for DMD assets (~200MB) and game code

---

## 🛠️ Installation Overview

| Step | Script | Purpose |
| :--- | :--- | :--- |
| **Step 0** | *(Prepare)* | Set up the Cactus Canyon VPX table normally and confirm it plays. Save DMD Position in DMDExt. |
| **Step 1** | `Install_PROC_CCC.bat` | Install Python 2.7, MinGW, and all CCC game files. |
| **Step 2** | `DMD-Position.bat` | Configure your DMD display method and position. |
| **Step 3** | `Enable-PROC-Cactus-Canyon-VPX-Table` | *(Optional)* Automates the `PROC = 1` table script edit. |

---

## 🤠 Step 0 — Prepare Your VPX Table

Download and configure **Cactus Canyon (Bally 1998) VPW 1.1.vpx** from VPUniverse as you normally would. Set up your Freezy DMD position and confirm the table runs correctly in VPX before proceeding.

---

## 🤠 Step 1 — Install P-ROC and CCC

Run **`Install_PROC_CCC.bat`** as Administrator. You will be asked which drive to install to — P-ROC always installs to the root as `X:\P-ROC`.

The installer automates the following:

- **Environment:** Extracts MinGW, installs Python 2.7.13 silently, builds YamlCPP and LibPinProc from source
- **Python Modules:** PyYAML, PyGame, PyPinProc, Pillow, PyOSC, PySDL2, NumPy, OpenCV, PyWin32
- **Game Assets:** Downloads CCC code from GitHub (CarnyPriest/CCCforVP) plus DMD and sound assets
- **Bridge:** Registers the VPX–P-ROC COM bridge for seamless communication
- **Launchers:** Creates `Test CCC.bat` in your P-ROC folder and generates an uninstaller

> [!NOTE]
> DMD assets and game code are downloaded during this step. Internet is required.

### 🐍 Python Isolation — Will This Break My Python 3?

No. This installer is carefully designed to be completely isolated from any other Python version on your system.

| Behaviour | Detail |
| :--- | :--- |
| **Custom install path** | Python 2.7 is installed to `X:\Python27` via MSI `TARGETDIR` — never the default Windows location |
| **Not added to system PATH** | Only `X:\MinGW\bin` and `X:\P-ROC\cmake\bin` are written to the machine PATH permanently. `X:\Python27` is never added |
| **Always called by full path** | Every script calls `"X:\Python27\python.exe"` explicitly — bare `python` or `py` commands in your terminal are unaffected |
| **Session-scoped PATH** | The installer uses `setlocal` so any temporary PATH changes during installation are discarded the moment the script exits |
| **Launchers are self-contained** | `Test CCC.bat` and all generated launchers prepend Python 2.7 to PATH inside their own `setlocal`/`endlocal` block and restore your original PATH on exit |

Opening a new terminal after installation, typing `python` or `python3` will resolve to exactly what it did before.

---

## 📺 Step 2 — Configure the DMD

Run **`DMD-Position.bat`**. This interactive wizard auto-detects your P-ROC installation across all drives and guides you through two display options.

> [!TIP]
> The auto-detected coordinates are read from your existing `dmddevice.ini` and are a close approximation — the CCC DMD window may not land in exactly the same position as your Freezy DMD on the first run. **You can re-run `DMD-Position.bat` as many times as you like.** The wizard offers a test launch at the end of each run so you can check the result and fine-tune the position until it is exactly where you want it.

### Option 1 — Native Python Color DMD *(Recommended)*

The game's own DMD window is placed directly on your screen or cabinet DMD monitor and patched to stay on top of VPX at all times.

- Highest colour accuracy and sharpest resolution
- Reads your `dmddevice.ini` automatically to match your existing Cactus Canyon DMD coordinates as a starting point
- Prompts for **pixel size** — recommend `4` for a single monitor, `8`–`12` for a cabinet DMD panel
- Includes the **Always-On-Top patch** *(see below)*

### Option 2 — Freezy DMDExt Mirror

A tiny 128×32 pixel capture window is placed in the bottom corner of your screen. DMDExt captures that area and mirrors it to your device.

- Best suited for **PinDMD** and **ZeDMD** hardware owners
- Also supports a software virtual DMD overlay via DMDExt
- Generates **`Launch_CCC_Freezy.bat`** in both your P-ROC folder and the installer directory
- For PinUp Popper: follow the [Other Emulators wiki guide](https://www.nailbuster.com/wikipinup/doku.php?id=emulator_other)

> [!IMPORTANT]
> Both modes apply the Always-On-Top patch. For Freezy mode this is essential — DMDExt captures a live screen region, so the CCC window must remain visible and on top for the mirror to work.

#### DMD Settings at a Glance

| Setting | Native | Freezy |
| :--- | :--- | :--- |
| Pixel Size | 4–12 (user choice) | 1 |
| Dot Style | ROUND | SQUARE |
| X / Y Position | Matched from `dmddevice.ini` or manual | Bottom corner of screen |
| Always-on-Top patch | ✓ | ✓ |

#### Freezy Frontend Files

The wizard generates two ready-to-use scripts in your P-ROC folder:

- 🚀 **`Launch_CCC_Freezy.bat`** — starts the DMDExt mirror. Use as your frontend pre-launch script.
- 🛑 **`Kill_DMDExt.bat`** — stops DMDExt cleanly. Use as your frontend post-game script.

---

## 💉 The Always-On-Top Patch *(New Feature)*

The original CCC release had no mechanism to keep the DMD window above VPX. Whenever VPX gained focus the DMD window would disappear behind the playfield, making it invisible during play.

This installer fixes that by injecting a small Win32 API call directly into the P-ROC display engine.

**File modified:**
```
X:\P-ROC\games\cactuscanyon\ep\ep_desktop_pygame.py
```

**Code injected** immediately after the pygame window is created:
```python
# Keep DMD window always on top of other windows (e.g. VPX table)
try:
    hwnd = pygame.display.get_wm_info()['window']
    ctypes.windll.user32.SetWindowPos(hwnd, -1, 0, 0, 0, 0, 0x0003)
except Exception:
    pass
```

**How it works:**

| Part | What it does |
| :--- | :--- |
| `get_wm_info()['window']` | Retrieves the Win32 window handle from pygame |
| `SetWindowPos` | Windows API call to control window Z-order |
| `-1` (`HWND_TOPMOST`) | Pins the window above all others, even when it loses focus |
| `0x0003` (`SWP_NOMOVE \| SWP_NOSIZE`) | Changes Z-order only — no move, no resize |
| `try/except` | Fails silently on non-Windows platforms |

`ctypes` is already imported by the original CCC code so no new dependencies are added. A backup of the original file is saved as `ep_desktop_pygame.py.bak` before any changes are made.

> [!TIP]
> To undo the patch at any time, run **`resources\patch_dmd_always_on_top_UNDO.bat`**. It restores the original file from the backup and removes the `.bak` so the cycle can be repeated cleanly.

---

## 🎰 Step 3 — Patch the VPX Table *(Optional)*

Run **`Enable-PROC-Cactus-Canyon-VPX-Table`**. This automates the one edit needed to enable P-ROC mode in the table script.

1. Locates your Visual Pinball **Tables** folder automatically (scans all drives)
2. Finds `Cactus Canyon (Bally 1998)*.vpx` — **your original is never modified**
3. Creates a copy named:
   - `Cactus Canyon Continued (Bally 1998) VPW 1.1.vpx` *(if source contains "VPW")*
   - `Cactus Canyon Continued (Bally 1998).vpx` *(otherwise)*
4. Extracts the VBScript using **vpxtool**
5. Changes `PROC = 0` → `PROC = 1` to enable the P-ROC game engine
6. Re-imports the patched script back into the table file

> [!NOTE]
> If the destination file already exists you will be asked to overwrite or enter a new name.

### Manual Patch (if preferred)

1. Copy `Cactus Canyon (Bally 1998).vpx` and rename the copy to `Cactus Canyon Continued (Bally 1998).vpx`
2. Open it in VPX → **Edit → Script**
3. Find the User Options section and change `PROC = 0` to `PROC = 1`
4. Save and close

---

## 🔧 Troubleshooting

### "Cannot find PROC" error when launching from VPX
The VPX–P-ROC COM bridge needs re-registering. Run **`VPX-Bridge-Re-Register.bat`** and restart your computer.

### P-ROC installed on a non-standard drive
All scripts auto-scan every drive letter (A–Z) for `\P-ROC`. If not found, you will be prompted to enter the path manually.

### DMD position needs adjusting
Re-run **`DMD-Position.bat`** as many times as needed. Each run updates `user_settings.yaml` with the new values. A test launch is offered at the end of each run.

### Revert the always-on-top patch
Run **`resources\patch_dmd_always_on_top_UNDO.bat`** to restore `ep_desktop_pygame.py` from its backup.

---

## ⚠️ VPX Version Note

> [!WARNING]
> **Cactus Canyon Continued is officially supported on VPX 10.7.4 only.**

This is due to `core.vbs` dependencies bundled with VPX. VPX 10.8.1 support is in progress.

A modified VPX 10.8 folder is available — release version with legacy core.vbs. Use at your own risk and **do not overwrite your existing VPX installation** with files from the modified build. In PinUp Popper, you can set the **Alternate Launcher** to the full path of the exe like the following example:

```
C:\vPinball\VPinballX64108-PROC\VPinballX64-PROC.exe
```

---

## 📁 File Reference

### Installer Scripts

| File | Purpose |
| :--- | :--- |
| `Install_PROC_CCC.bat` | Full P-ROC + CCC installation |
| `DMD-Position.bat` | Interactive DMD setup wizard |
| `Enable-PROC-Cactus-Canyon-VPX-Table` | Automated VPX table patcher |
| `VPX-Bridge-Re-Register.bat` | Fix VPX–P-ROC COM bridge errors |
| `Uninstall.bat` | Remove P-ROC, Python 2.7, and MinGW |
| `resources\patch_dmd_always_on_top.bat` | Apply always-on-top patch standalone |
| `resources\patch_dmd_always_on_top_UNDO.bat` | Revert always-on-top patch |

### Generated After Install

| File | Location | Purpose |
| :--- | :--- | :--- |
| `Test CCC.bat` | `X:\P-ROC\` | Launch CCC directly for testing |
| `Launch_CCC_Freezy.bat` | `X:\P-ROC\` and installer dir | Start DMDExt mirror (Freezy mode) |
| `Kill_DMDExt.bat` | `X:\P-ROC\` | Stop DMDExt (frontend post-game script) |

---

## ❤️ Credits

- **Original CCC Code:** epthegeek — [soldmy.org](http://soldmy.org/pin/ccc/index.php?title=Main_Page) / [GitHub](https://github.com/epthegeek/cactuscanyon)
- **CCC for VP Port:** CarnyPriest / [CCCforVP](https://github.com/CarnyPriest/CCCforVP)
- **VPinWorkshop:** [VPW](https://vpinworkshop.com/work/)
- **Framework:** Multimorphic (P-ROC) & pyprocgame *(software simulation mode)*
- **DMD Mirroring:** freezy / [dmd-extensions](https://github.com/freezy/dmd-extensions)
- **VPX Tool:** francisdb / [vpxtool](https://github.com/francisdb/vpxtool)

---

## ⚠️ Disclaimer

> [!IMPORTANT]
> **This is a modification of the original code. Do not contact the original authors of the P-ROC project about this game code — they are two separate projects.**
> For support with the Visual Pinball version, visit **[vpinhub.com](http://vpinhub.com)**.

Port of Cactus Canyon Continued to Visual Pinball. All original coding by **epthegeek**.

- [http://soldmy.org/pin/ccc/index.php?title=Main_Page](http://soldmy.org/pin/ccc/index.php?title=Main_Page)
- [https://github.com/epthegeek/cactuscanyon](https://github.com/epthegeek/cactuscanyon)

This project is not affiliated with, or endorsed by, WMS Gaming and/or whomever currently holds the rights to the pinball properties under the Bally name.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
