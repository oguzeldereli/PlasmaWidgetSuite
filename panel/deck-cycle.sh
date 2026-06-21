#!/usr/bin/env bash
# Activate the next / previous application window in taskbar order
# (_NET_CLIENT_LIST, the same order the Lattice Deck shows), wrapping around.
#
#   deck-cycle.sh next   -> focus the window to the right on the bar
#   deck-cycle.sh prev   -> focus the window to the left on the bar
#
# X11 only (uses wmctrl + xprop).
set -euo pipefail
dir="${1:-next}"

# Ordered window ids, filtered to normal windows (skip the desktop and panels,
# exactly what the Deck's TasksModel excludes).
ids=()
while read -r id _; do
    [ -z "$id" ] && continue
    t="$(xprop -id "$id" _NET_WM_WINDOW_TYPE 2>/dev/null || true)"
    case "$t" in
        *_NET_WM_WINDOW_TYPE_DESKTOP*|*_NET_WM_WINDOW_TYPE_DOCK*) continue ;;
    esac
    ids+=("$id")
done < <(wmctrl -l)

n=${#ids[@]}
[ "$n" -eq 0 ] && exit 0

active="$(xprop -root _NET_ACTIVE_WINDOW 2>/dev/null | grep -oE '0x[0-9a-fA-F]+' | head -1 || echo 0x0)"
adec=$(( active ))

idx=-1
for i in "${!ids[@]}"; do
    if [ $(( ${ids[$i]} )) -eq "$adec" ]; then idx=$i; break; fi
done

if [ "$idx" -lt 0 ]; then
    target=0
elif [ "$dir" = "prev" ]; then
    target=$(( (idx - 1 + n) % n ))
else
    target=$(( (idx + 1) % n ))
fi

wmctrl -i -a "${ids[$target]}"
