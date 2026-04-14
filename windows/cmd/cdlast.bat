@echo off
:: cdlast.bat
:: Instantly cd's your Command Prompt into the folder currently open
:: in the foreground Windows Explorer window.
::
:: Requirements:
::   - Python 3 in PATH (or the Python Launcher `py` installed)
::   - pywin32 and psutil  ->  pip install pywin32 psutil
::
:: Usage: drag this file into a CMD window, or call it from a doskey macro.
:: Note: because CMD can't source external scripts into the current session
:: the way PowerShell can, this file must be called directly (not via `call`
:: from another script) so the `cd` and drive-switch commands take effect
:: in the intended window.

:: ---------------------------------------------------------------------------
:: Resolve the path of getFolderURL.py relative to this script's location.
:: %~dp0 expands to the directory containing cdlast.bat, so the two files
:: can live together anywhere without hardcoding paths.
:: ---------------------------------------------------------------------------
set "SCRIPT_DIR=%~dp0"

:: ---------------------------------------------------------------------------
:: Call Python to get the Windows-format path of the active Explorer window.
:: We pass "win32" so getFolderURL.py returns backslash-separated paths.
:: ---------------------------------------------------------------------------
for /f "delims=" %%a in ('py "%SCRIPT_DIR%getFolderURL.py" win32 2^>nul') do set "URL=%%a"

:: Fall back to `python` if the `py` launcher is not available
if not defined URL (
    for /f "delims=" %%a in ('python "%SCRIPT_DIR%getFolderURL.py" win32 2^>nul') do set "URL=%%a"
)

if not defined URL (
    echo [cdlast] Error: could not resolve Explorer window path.
    echo Make sure Python is in your PATH and pywin32/psutil are installed.
    exit /b 1
)

:: ---------------------------------------------------------------------------
:: Navigate to the resolved path.
:: CMD's `cd` only changes directory within the current drive, so we also
:: need to switch drives explicitly by running the drive letter as a command
:: (e.g. typing  C:  in CMD switches to the C drive).
:: ---------------------------------------------------------------------------
cd /d "%URL%"
