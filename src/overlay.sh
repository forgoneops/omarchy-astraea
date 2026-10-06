#!/usr/bin/env bash
# Start/stop the animated HUD overlay.   usage: src/overlay.sh start|stop|restart|status|log
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG=/tmp/astraea-hud.log
case "$1" in
  start)   [ "$(cat "$ROOT/config/mode" 2>/dev/null)" = animated ] || { echo "HUD mode is static - overlay not started (src/hud-mode.sh animated)"; exit 0; }
           pgrep -f "quickshell.*astraea-voss/overlay" >/dev/null && { echo "already running"; exit 0; }
           nohup quickshell -n -p "$ROOT/overlay" >"$LOG" 2>&1 & disown; sleep 1.5; pgrep -f "quickshell.*astraea-voss/overlay" >/dev/null && echo started || { echo "failed - see $LOG"; tail -20 "$LOG"; exit 1; } ;;
  stop)    pkill -f "quickshell.*astraea-voss/overlay" && echo stopped || echo "not running" ;;
  restart) "$0" stop; sleep 0.5; "$0" start ;;
  status)  pgrep -af "quickshell.*astraea-voss/overlay" || echo "not running" ;;
  log)     tail -40 "$LOG" ;;
  *)       echo "usage: $0 start|stop|restart|status|log"; exit 1 ;;
esac
