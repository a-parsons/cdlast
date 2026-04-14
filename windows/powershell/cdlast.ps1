# cdlast.ps1
# Instantly cd's your terminal into the folder currently open
# in the foreground Windows Explorer window.
#
# Usage: . .\cdlast.ps1   (dot-source to affect the current shell session)

# ---------------------------------------------------------------------------
# Win32 API bindings via P/Invoke
# These are needed to identify which window is currently in the foreground
# and to read its title/handle — information PowerShell can't get natively.
# ---------------------------------------------------------------------------
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    using System.Text;

    public class Win32 {
        // Returns the window handle of the foreground (active) window
        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        public static extern IntPtr GetForegroundWindow();

        // Returns the length of a window's title bar text
        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        public static extern int GetWindowTextLength(IntPtr hWnd);

        // Copies a window's title bar text into a StringBuilder buffer
        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int cch);

        // Returns the thread/process ID that created the given window
        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        public static extern int GetWindowThreadProcessId(IntPtr hWnd, out int lpdwProcessId);
    }
"@

# ---------------------------------------------------------------------------
# Locate the foreground Explorer window
# ---------------------------------------------------------------------------

# Get all open Explorer windows via the Shell COM object
$shellApp     = New-Object -ComObject Shell.Application
$shellWindows = $shellApp.Windows()

$locationURL  = $null

# Poll until we find a foreground window that is an Explorer file window.
# This handles cases where the script is invoked before the user has
# focused an Explorer window — though in typical use it resolves immediately.
:search while ($true) {

    # Get the handle of whichever window is currently focused
    $foregroundHwnd = [Win32]::GetForegroundWindow()

    # Filter shell windows to only those showing a local filesystem path
    $explorerWindows = $shellWindows | Where-Object { $_.LocationURL -like "file:*" }

    foreach ($window in $explorerWindows) {
        # Match the Explorer window whose handle equals the foreground handle
        if ($foregroundHwnd -eq $window.HWND) {
            $locationURL = $window.LocationURL
            break search
        }
    }
}

# ---------------------------------------------------------------------------
# Convert the file:// URL to a plain Windows path
# ---------------------------------------------------------------------------

# Strip the file:/// scheme prefix
$locationURL = [string]$locationURL
$locationURL = $locationURL -replace "^file:///", ""

# Convert forward slashes to backslashes (Windows path convention)
$locationURL = $locationURL -replace "/", "\"

# Decode any percent-encoded characters (e.g. %20 → space)
$locationURL = [System.Uri]::UnescapeDataString($locationURL)

# ---------------------------------------------------------------------------
# Navigate the current shell session to the resolved path
# ---------------------------------------------------------------------------
Set-Location -LiteralPath $locationURL
