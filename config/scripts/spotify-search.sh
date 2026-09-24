#!/usr/bin/env bash
# Spotify track search for the Quickshell Spotify popup.
#
# Ported from the eww widget's spotify_search.sh + spotify_api.sh. Uses the
# app-only Client Credentials flow (no user login/browser step) because search
# is public data — playback is controlled through `soloist ctl` instead.
#
# The Client ID/Secret live in gnome-keyring (service `spotify-search`), never
# in this repo. Only the derived short-lived access token is cached, under
# $XDG_RUNTIME_DIR (see systemd/.setup for the one-time store commands).
#
# Usage: spotify-search.sh "<query>"
# Emits a JSON array of {uri, name, artist}.
set -euo pipefail

cache_dir="${XDG_RUNTIME_DIR:-/tmp}/quickshell-spotify"
token_cache="$cache_dir/search_token.json"

access_token() {
  local client_id client_secret
  client_id=$(secret-tool lookup service spotify-search key client-id || true)
  client_secret=$(secret-tool lookup service spotify-search key client-secret || true)
  if [[ -z "$client_id" || -z "$client_secret" ]]; then
    echo "spotify: credentials not in keyring — see systemd/.setup" >&2
    return 1
  fi

  mkdir -p "$cache_dir"
  if [[ -f "$token_cache" ]]; then
    local now expires_at cached
    now=$(date +%s)
    expires_at=$(jq -r '.expires_at // 0' "$token_cache" 2>/dev/null)
    if [[ "$expires_at" =~ ^[0-9]+$ ]] && (( now < expires_at - 30 )); then
      cached=$(jq -r '.access_token' "$token_cache")
      [[ -n "$cached" && "$cached" != "null" ]] && { echo "$cached"; return 0; }
    fi
  fi

  local resp token expires_in
  resp=$(curl -fsS -X POST https://accounts.spotify.com/api/token \
    -u "${client_id}:${client_secret}" \
    -d grant_type=client_credentials) || {
    echo "spotify: token request failed" >&2
    return 1
  }

  token=$(jq -r '.access_token // empty' <<<"$resp")
  expires_in=$(jq -r '.expires_in // 3600' <<<"$resp")
  [[ -z "$token" ]] && { echo "spotify: no access_token in response" >&2; return 1; }

  jq -n --arg t "$token" --argjson exp "$(( $(date +%s) + expires_in ))" \
    '{access_token: $t, expires_at: $exp}' >"$token_cache"
  chmod 600 "$token_cache"

  echo "$token"
}

query="${1:-}"
if [[ -z "$query" ]]; then
  echo "[]"
  exit 0
fi

encoded=$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$query")
token=$(access_token)

curl -fsS "https://api.spotify.com/v1/search?q=${encoded}&type=track&limit=8" \
  -H "Authorization: Bearer $token" |
  jq -c '[.tracks.items[] | {uri, name, artist: (.artists | map(.name) | join(", "))}]'
