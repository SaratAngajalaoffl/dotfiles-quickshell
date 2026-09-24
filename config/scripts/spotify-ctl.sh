#!/usr/bin/env bash
# Playback control for the Quickshell Spotify popup, via `soloist ctl`.
#
# Ported from the eww widget's spotify_ctl.sh. Soloist needs no Web API token
# and no MPRIS, so all transport goes through its own CLI.
#
# Usage:
#   spotify-ctl.sh toggle           # play/pause
#   spotify-ctl.sh next / prev
#   spotify-ctl.sh play-uri <uri>
#   spotify-ctl.sh seek <ms>
#   spotify-ctl.sh shuffle <on|off>
#   spotify-ctl.sh repeat <off|context|track>
set -euo pipefail

# soloist lives in ~/bin; the session PATH does not always include it.
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

round_ms() { awk -v v="$1" 'BEGIN { printf "%d", v + 0.5 }'; }

cmd="${1:?usage: spotify-ctl.sh <command> [args...]}"
shift

case "$cmd" in
  toggle)
    status=$(soloist ctl now --json 2>/dev/null | jq -r '.status // "idle"')
    if [[ "$status" == "playing" ]]; then
      soloist ctl pause
    else
      soloist ctl play
    fi
    ;;
  next)  soloist ctl next ;;
  prev)  soloist ctl prev ;;
  play-uri) soloist ctl play "${1:?uri required}" ;;
  seek)  soloist ctl seek "$(round_ms "${1:?ms required}")" ;;
  shuffle) soloist ctl shuffle "${1:?on|off required}" ;;
  repeat)  soloist ctl repeat "${1:?off|context|track required}" ;;
  *)
    echo "unknown command: $cmd" >&2
    exit 1
    ;;
esac
