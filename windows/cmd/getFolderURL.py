# getFolderURL.py
# Returns the filesystem path of the currently focused Windows Explorer window.
#
# Usage:
#   python getFolderURL.py           -> Unix-style path  (for MSYS2 / Git Bash)
#   python getFolderURL.py win32     -> Windows-style path (for CMD / PowerShell)
#
# Only the resolved path is printed to stdout so callers can capture it cleanly.

import sys
import logging
import urllib.parse

import win32gui
import win32process
import win32com.client
import psutil

# ---------------------------------------------------------------------------
# Logging (disabled by default — enable for debugging)
# ---------------------------------------------------------------------------
logger = logging.getLogger()
logger.disabled = True


def get_foreground_explorer_url() -> str:
    """
    Return the LocationURL of the Explorer window that is currently in the
    foreground, or an empty string if no Explorer window is focused.

    Matching strategy: compare the foreground window's title text against each
    open Explorer window's LocationName (the human-readable folder name shown
    in the title bar). This avoids a direct HWND comparison, which is harder
    to reach cleanly via the Shell COM object in Python.
    """
    fore_hwnd    = win32gui.GetForegroundWindow()
    window_title = win32gui.GetWindowText(fore_hwnd)
    logging.warning(f"Foreground window title: {window_title!r}")

    shell = win32com.client.Dispatch("Shell.Application")

    for window in shell.Windows():
        # Only consider windows that are File Explorer instances
        if window.Name != "File Explorer":
            continue
        # Match the Explorer window whose displayed folder name equals the title
        if window.LocationName == window_title:
            logging.warning(f"Matched LocationURL: {window.LocationURL!r}")
            return window.LocationURL

    return ""


def resolve_path(location_url: str, mode: str) -> str:
    """
    Convert a file:/// URL returned by the Shell COM object into a usable path.

    mode='win32'  ->  Windows path  (e.g. C:\\Users\\name\\Documents)
    mode=''       ->  Unix-style    (e.g. /c/Users/name/Documents) for MSYS2/Git Bash
    """
    # Strip the file:/// scheme
    path = location_url.replace("file:///", "")

    # Decode all percent-encoded characters (e.g. %20 -> space, %23 -> #)
    path = urllib.parse.unquote(path)

    if mode == "win32":
        # Convert forward slashes to backslashes for Windows paths
        path = path.replace("/", "\\")
    else:
        # Convert  C:/some/path  ->  /c/some/path  (MSYS2 / Git Bash convention)
        if len(path) >= 2 and path[1] == ":":
            drive_letter = path[0].lower()
            path = "/" + drive_letter + "/" + path[3:]  # drop "X:/"

    return path


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else ""

    location_url = ""
    while not location_url:
        location_url = get_foreground_explorer_url()
        logging.warning("Retrying..." if not location_url else "Found URL.")

    print(resolve_path(location_url, mode))


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        logging.warning(exc)
        sys.exit(1)
