#!/usr/bin/env bash
# Pinned playlists for the Quickshell Spotify page, with their cover art.
#
# Reads spotify-playlists.json (next to this script) and adds an `art` URL to
# each entry. Covers come from Spotify's public oEmbed endpoint, which needs
# no credentials and — unlike the Web API under the Client Credentials flow —
# also answers for Spotify-generated playlists (On Repeat, Daily Mix, ...).
# Found URLs are cached, so only new entries hit the network.
#
# Usage: spotify-playlists.sh
# Emits a JSON array of {name, uri, art}.
set -euo pipefail

here=$(dirname "$(readlink -f "$0")")
list="$here/spotify-playlists.json"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell"
cache="$cache_dir/spotify-art.json"

mkdir -p "$cache_dir"
[[ -s "$cache" ]] || echo '{}' >"$cache"

while IFS= read -r uri; do
  [[ -n "$(jq -r --arg u "$uri" '.[$u] // empty' "$cache")" ]] && continue
  # spotify:playlist:<id> -> https://open.spotify.com/playlist/<id>
  path=${uri#spotify:}
  url="https://open.spotify.com/${path//://}"
  art=$(curl -fsS --max-time 5 --get "https://open.spotify.com/oembed" --data-urlencode "url=$url" \
          | jq -r '.thumbnail_url // empty' 2>/dev/null || true)
  [[ -z "$art" ]] && continue
  jq --arg u "$uri" --arg a "$art" '.[$u] = $a' "$cache" >"$cache.tmp" && mv "$cache.tmp" "$cache"
done < <(jq -r '.[].uri' "$list")

jq -c --slurpfile art "$cache" 'map(. + {art: ($art[0][.uri] // "")})' "$list"
