# cdlast

**Jump your terminal instantly into the folder open in your file manager.**

`cdlast` reads the path from whichever file manager window is currently in focus and `cd`s your terminal session directly into it — no typing, no copying, no dragging.

---

## Variants

| Location | Platform | Shell | File Manager | Dependencies |
|---|---|---|---|---|
| `windows/powershell/` | Windows 10/11 | PowerShell 5.1+ | Explorer | None |
| `windows/cmd/` | Windows 10/11 | Command Prompt | Explorer | Python 3 + pywin32 + psutil |
| `linux/` | Linux Mint | Bash | Nemo | xdotool |

---

## Repo structure

```
cdlast/
├── windows/
│   ├── powershell/
│   │   └── cdlast.ps1          # Dot-source in PowerShell
│   └── cmd/
│       ├── cdlast.bat          # Run directly in Command Prompt
│       ├── getFolderURL.py     # Python helper called by the bat
│       └── requirements.txt
└── linux/
    └── setup_cdlast.sh         # One-time installer for Linux Mint
```

---

## Usage

### Windows — PowerShell

1. Make sure the Explorer window you want is in the foreground.
2. **Dot-source** the script to run it in your current shell scope:

```powershell
. .\windows\powershell\cdlast.ps1
```

> **Why dot-source?** A normally invoked script runs in a child scope — any `cd` it performs disappears when it exits. Dot-sourcing runs the script inside your current session so the directory change sticks.

#### Optional: permanent shorthand

Add to your PowerShell profile (`$PROFILE`):

```powershell
function cdlast { . "C:\path\to\windows\powershell\cdlast.ps1" }
```

---

### Windows — Command Prompt

#### One-time setup

```cmd
pip install pywin32 psutil
```

`cdlast.bat` and `getFolderURL.py` must stay in the same folder — the bat file locates the Python script relative to itself.

#### Running

1. Make sure the Explorer window you want is in the foreground.
2. Call the batch file:

```cmd
C:\path\to\windows\cmd\cdlast.bat
```

#### Optional: permanent shorthand

Add a `doskey` macro to a startup batch file (set via `HKCU\Software\Microsoft\Command Processor\AutoRun`):

```cmd
doskey cdlast=C:\path\to\windows\cmd\cdlast.bat
```

---

### Linux Mint — Bash

#### One-time setup

Run the installer once:

```bash
bash linux/setup_cdlast.sh
```

This will:
- Install `xdotool` if needed
- Enable full-path display in Nemo's title bar (required for path detection)
- Add a `cdlast()` function to your `~/.bashrc`

Then reload your shell:

```bash
source ~/.bashrc
```

#### Running

1. Open a folder in **Nemo**.
2. Switch to your terminal and type:

```bash
cdlast
```

> Unlike the Windows scripts, `cdlast` on Linux Mint becomes a persistent shell function after setup — no sourcing needed on each use.

---

## How it works

### Windows — PowerShell

Uses the **Win32 API** via PowerShell P/Invoke to get the foreground window handle, then walks all open Shell COM windows to find the matching Explorer instance by HWND. The `LocationURL` property is read and converted from a `file:///` URL to a plain Windows path.

### Windows — Command Prompt

The batch script calls `getFolderURL.py`, which uses **pywin32** to get the foreground window title and walks Shell COM windows to find the Explorer instance whose displayed folder name matches. The resolved path is captured from stdout by the batch script. Because CMD's `cd` only operates within the current drive, a `cd /d` call handles both the path and drive switch in one step.

### Linux Mint

The installed `cdlast()` function uses **xdotool** to enumerate all open Nemo windows and collect their titles. Nemo displays the full path in its title bar (once `show-full-path-titles` is enabled), formatted as `FolderName - /full/path`. The function extracts the path portion and navigates to it.

---

## Requirements

| Variant | Requirements |
|---|---|
| PowerShell | Windows 10/11 · PowerShell 5.1+ (built-in) |
| Command Prompt | Windows 10/11 · Python 3.6+ · `pip install pywin32 psutil` |
| Linux Mint | Linux Mint (Cinnamon) · `xdotool` (auto-installed by setup script) |

---

## License

MIT — see [LICENSE](LICENSE).
# cdlast
