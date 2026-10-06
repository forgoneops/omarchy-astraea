#!/usr/bin/env bash
# Choose how the Astraea HUD is shown.
#   hud-mode.sh static      text baked into the wallpapers (no extra process, zero overhead)
#   hud-mode.sh animated    text-free wallpapers + live animated overlay (~1.5% of one core, ~200 MB RAM)
#   hud-mode.sh toggle      flip between the two
#   hud-mode.sh status      show the current mode and what is actually installed
set -euo pipefail
ROOT="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
MODE_FILE="$ROOT/config/mode"
THEMES="$HOME/.config/omarchy/themes"
current_mode() { cat "$MODE_FILE" 2>/dev/null || echo static; }

installed_kind() {   # compare one installed wallpaper with the static / base builds
  local f inst h
  f=$(ls "$ROOT"/dist/section9/scene-*.png 2>/dev/null | head -1) || true
  [ -n "${f:-}" ] || { echo "unknown (nothing built yet)"; return; }
  inst=$(ls "$THEMES"/astraea-section-9/backgrounds/*-"$(basename "$f" .png | sed 's/^scene-[0-9]*-//')".png 2>/dev/null | head -1) || true
  [ -n "${inst:-}" ] || { echo "not installed"; return; }
  h=$(sha1sum < "$inst" | cut -c1-8)
  [ "$h" = "$(sha1sum < "$f" | cut -c1-8)" ] && { echo "static (text baked in)"; return; }
  [ -f "$ROOT/dist/base/section9/$(basename "$f")" ] && [ "$h" = "$(sha1sum < "$ROOT/dist/base/section9/$(basename "$f")" | cut -c1-8)" ] && { echo "animated (text-free base)"; return; }
  echo "other / older build"
}

apply() {
  local m="$1"
  [ "$m" = static ] || [ "$m" = animated ] || { echo "mode must be static or animated"; exit 1; }
  # build whatever this mode needs if it is missing
  if [ "$m" = static ] && ! ls "$ROOT"/dist/*/scene-*.png >/dev/null 2>&1; then python3 "$ROOT/src/build_hud.py" >/dev/null; fi
  if [ "$m" = animated ] && { ! ls "$ROOT"/dist/base/*/scene-*.png >/dev/null 2>&1 || [ ! -f "$ROOT/overlay/data.json" ]; }; then python3 "$ROOT/src/build_hud.py" --base >/dev/null; fi
  echo "$m" > "$MODE_FILE"                                   # overlay.sh start/autostart read this
  if [ "$m" = static ]; then "$ROOT/src/overlay.sh" stop >/dev/null 2>&1 || true; fi
  python3 "$ROOT/src/install_to_themes.py" --mode "$m" | grep -E '^mode|installed|!!' || true
  # Omarchy copies a theme into its state dir when it is applied, so re-apply the current one to show the new files
  local cur; cur="$(omarchy theme current 2>/dev/null | head -1)"
  case "$cur" in Astraea*) omarchy theme set "$cur" >/dev/null 2>&1 || true ;; esac
  if [ "$m" = animated ]; then "$ROOT/src/overlay.sh" restart; fi
  echo "HUD mode: $m"
}

case "${1:-status}" in
  static|animated) apply "$1" ;;
  toggle)  [ "$(current_mode)" = static ] && apply animated || apply static ;;
  status)  echo "mode (saved):  $(current_mode)"
           echo "installed:     $(installed_kind)"
           echo "overlay:       $("$ROOT/src/overlay.sh" status 2>/dev/null | grep -c 'quickshell -n' | sed 's/^0$/not running/;s/^[1-9].*$/running/')" ;;
  *) echo "usage: $(basename "$0") static|animated|toggle|status"; exit 1 ;;
esac
