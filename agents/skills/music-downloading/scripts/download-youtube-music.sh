#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s [--chrome-cookies] YOUTUBE_URL\n' "${0##*/}" >&2
  exit 2
}

use_chrome_cookies=false
if [[ "${1:-}" == "--chrome-cookies" ]]; then
  use_chrome_cookies=true
  shift
fi

[[ $# -eq 1 ]] || usage

music_directory='/home/neo/Music'
url="$1"
cookie_args=()
if [[ "$use_chrome_cookies" == true ]]; then
  cookie_args=(--cookies-from-browser chrome)
fi

mkdir -p "$music_directory"
exec yt-dlp \
  "${cookie_args[@]}" \
  --no-playlist \
  --continue \
  --extract-audio \
  --audio-format mp3 \
  --audio-quality 0 \
  --embed-metadata \
  --embed-thumbnail \
  --convert-thumbnails jpg \
  --output "$music_directory/%(title)s.%(ext)s" \
  --print after_move:filepath \
  "$url"
