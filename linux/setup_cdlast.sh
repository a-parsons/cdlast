#!/bin/bash
# setup_cdlast.sh
# One-time installer that adds a persistent `cdlast` command to your shell.
# After running this script, open any folder in Nemo and type `cdlast` in
# your terminal to jump straight into it.
#
# What this script does:
#   1. Installs xdotool if it is not already present
#   2. Enables full-path display in Nemo's title bar (required for path detection)
#   3. Writes a cdlast() function into ~/.bashrc

set -e

BASHRC="$HOME/.bashrc"

# ---------------------------------------------------------------------------
# 1. Ensure xdotool is available
#    xdotool lets us query open window names from the shell.
# ---------------------------------------------------------------------------
if ! command -v xdotool &>/dev/null; then
    echo "xdotool not found — installing..."
    sudo apt install -y xdotool
    echo "xdotool installed."
else
    echo "xdotool already installed. Skipping."
fi

# ---------------------------------------------------------------------------
# 2. Enable full path in Nemo's title bar
#    By default Nemo only shows the folder name (e.g. "Documents"), not the
#    full path (e.g. "/home/user/Documents"). The cdlast function relies on
#    the full path appearing in the window title, so this setting is required.
# ---------------------------------------------------------------------------
echo "Enabling full path in Nemo title bar..."
gsettings set org.nemo.preferences show-full-path-titles true
echo "Done."

# ---------------------------------------------------------------------------
# 3. Inject cdlast() into ~/.bashrc
#    Remove any previous installation first so re-running this script is safe.
# ---------------------------------------------------------------------------
sed -i '/# >>> cdlast/,/# <<< cdlast/d' "$BASHRC"

cat >> "$BASHRC" << 'EOF'

# >>> cdlast
cdlast() {
    # Find all open Nemo windows and collect any that are showing a full path.
    # Nemo window titles take the form:  "FolderName - /full/path/to/folder"
    # when show-full-path-titles is enabled, so we filter for " - /" and
    # extract everything after the last " - " separator.
    local path
    path=$(xdotool search --class Nemo 2>/dev/null \
        | while read -r wid; do
            xdotool getwindowname "$wid" 2>/dev/null
          done \
        | grep ' - /' \
        | sed 's/.* - //' \
        | tail -1)

    if [ -z "$path" ]; then
        echo "cdlast: no open Nemo window with a visible path found." >&2
        echo "       Make sure at least one Nemo window is open." >&2
        return 1
    fi

    cd "$path" && echo "→ $path"
}
# <<< cdlast
EOF

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " cdlast installed successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo " Reload your shell:"
echo "   source ~/.bashrc"
echo ""
echo " Then open a folder in Nemo and run:"
echo "   cdlast"
echo ""
