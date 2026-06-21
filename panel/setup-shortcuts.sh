#!/usr/bin/env bash
# Global shortcuts for traversing windows along the Lattice Deck.
#   ./setup-shortcuts.sh           apply  (Meta+] = next, Meta+[ = previous)
#   ./setup-shortcuts.sh remove    remove them
#
# Implemented as a KWin script (works on Wayland AND X11) that registers its own
# shortcuts and un-minimises + activates the target window. Rebind in
# System Settings → Shortcuts → KWin → "Lattice Deck …".
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPS="$HOME/.local/share/applications"
KWINS="$HOME/.local/share/kwin/scripts"
KGA="$(command -v kglobalacceld 2>/dev/null || echo /usr/libexec/kglobalacceld)"
SCRIPT_ID="lattice-deck"

reconfigure_kwin() { qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true; }
kwin_enable()  { kwriteconfig6 --file kwinrc --group Plugins --key "${SCRIPT_ID}Enabled" "$1"; }

# Remove the dead X11 attempt (wmctrl .desktop launchers + their shortcuts), so
# Meta+] / Meta+[ are free for the KWin script to claim.
clean_old_x11() {
    kquitapp6 kglobalacceld >/dev/null 2>&1 || killall kglobalacceld 2>/dev/null || true
    for i in $(seq 1 30); do pgrep -x kglobalacceld >/dev/null 2>&1 || break; sleep 0.5; done
    for id in lattice-deck-next.desktop lattice-deck-prev.desktop; do
        kwriteconfig6 --file kglobalshortcutsrc --group services --group "$id" --key _launch --delete 2>/dev/null || true
    done
    (setsid "$KGA" >/dev/null 2>&1 &) || (nohup "$KGA" >/dev/null 2>&1 &) || true
    rm -f "$APPS/lattice-deck-next.desktop" "$APPS/lattice-deck-prev.desktop"
    update-desktop-database "$APPS" >/dev/null 2>&1 || true
}

if [ "${1:-apply}" = "remove" ]; then
    kwin_enable false
    reconfigure_kwin
    rm -rf "$KWINS/$SCRIPT_ID"
    echo "✓ removed deck traversal KWin script"
    exit 0
fi

clean_old_x11

# install / refresh the KWin script package
mkdir -p "$KWINS"
rm -rf "$KWINS/$SCRIPT_ID"
cp -r "$DIR/kwin-deck" "$KWINS/$SCRIPT_ID"

# toggle off→on so a changed script is actually reloaded
kwin_enable false; reconfigure_kwin
kwin_enable true;  reconfigure_kwin

echo "✓ KWin script installed — Meta+] next window, Meta+[ previous (un-minimises + activates)"
echo "  rebind in System Settings → Shortcuts → KWin → \"Lattice Deck …\""
