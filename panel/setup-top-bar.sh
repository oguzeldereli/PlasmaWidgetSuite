#!/usr/bin/env bash
# Apply or remove the Lattice top bar (launcher + global menu + deck + rail + clock).
#   ./setup-top-bar.sh         apply (idempotent)
#   ./setup-top-bar.sh remove  remove it
#
# Apply binds Super/Meta to the top-bar launcher (kickerdash, full-screen so it
# always opens centered) and disables the orphaned generic "activate application
# launcher" shortcut that popped up in the top-left corner.
#
# The shortcut registry is owned by kglobalacceld (it rewrites the file from
# memory), so the edit must happen while BOTH plasmashell and kglobalacceld are
# stopped — otherwise the change is clobbered.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KGS="$HOME/.config/kglobalshortcutsrc"
KGA="$(command -v kglobalacceld 2>/dev/null || echo /usr/libexec/kglobalacceld)"

eval_js() { qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat "$1")"; }

wait_gone() { for i in $(seq 1 30); do pgrep -x "$1" >/dev/null 2>&1 || return 0; sleep 0.5; done; }
stop()  { kquitapp6 "$1" >/dev/null 2>&1 || killall "$1" 2>/dev/null || true; wait_gone "$1"; }
start() { (setsid "$1" >/dev/null 2>&1 &) || (nohup "$1" >/dev/null 2>&1 &) || true; }

# plasmashell goes through its systemd user unit: started from this shell it
# would inherit the shell's env (e.g. Conda's __EGL_VENDOR_LIBRARY_DIRS) and pass
# it to every app it launches, breaking their GPU acceleration.
SHELL_UNIT=plasma-plasmashell.service
has_unit() { systemctl --user cat "$SHELL_UNIT" >/dev/null 2>&1; }
stop_shell() {
    if has_unit; then systemctl --user stop "$SHELL_UNIT" || true; fi
    stop plasmashell                  # also catches an instance started outside systemd
}
start_shell() {
    if has_unit; then systemctl --user start "$SHELL_UNIT"
    else (setsid env -u __EGL_VENDOR_LIBRARY_DIRS plasmashell >/dev/null 2>&1 &) || true; fi
}

disable_generic() { [ -f "$KGS" ] && sed -i 's/^\(activate application launcher=\)[^,]*,/\1none,/' "$KGS"; }
restore_generic() { [ -f "$KGS" ] && sed -i 's/^\(activate application launcher=\)[^,]*,/\1Meta\\tAlt+F1,/' "$KGS"; }
# drop stale kickerdash Meta entries left by earlier re-applies, keep only $1 (live id)
clean_stale() { [ -f "$KGS" ] && [ -n "$1" ] && sed -i "/=Meta,none,Activate Application Dashboard Widget\$/{/^activate widget $1=/!d}" "$KGS"; }
live_kickerdash_id() {
    qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
'var ps=panels();for(var i=0;i<ps.length;i++){if(ps[i].location==="top"){var ws=ps[i].widgets();for(var j=0;j<ws.length;j++){if(ws[j].type==="org.kde.plasma.kickerdash"){print(ws[j].id);}}}}' 2>/dev/null | tr -dc '0-9'
}

action="${1:-apply}"
LIVE=""

if [ "$action" = "remove" ]; then
    eval_js "$DIR/remove-top-bar.js"
else
    eval_js "$DIR/top-bar.js"      # builds panel + sets kickerdash globalShortcut=Meta
    LIVE="$(live_kickerdash_id)"   # capture before stopping plasmashell
fi

echo "↻ cycling plasmashell + kglobalacceld to apply shortcut change…"
stop_shell
stop kglobalacceld                  # saves memory→file, then exits; now safe to edit

if [ "$action" = "remove" ]; then
    restore_generic
else
    disable_generic
    clean_stale "$LIVE"
fi

start "$KGA"
sleep 1
start_shell

if [ "$action" = "remove" ]; then
    echo "✓ removed Lattice top bar (Meta restored to default launcher action)"
else
    echo "✓ top bar applied — Super now opens the launcher centered"
fi
