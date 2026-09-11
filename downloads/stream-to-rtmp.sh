#!/usr/bin/env bash
set -euo pipefail
# Optional fallback for Modul 15 if OBS is unavailable.
# Example: ./stream-to-rtmp.sh rtmp://192.168.10.11/live/kelompok1
URL="${1:-}"
[ -n "$URL" ] || { echo "Usage: $0 rtmp://HOST/live/STREAMKEY"; exit 2; }
DIR="$(cd "$(dirname "$0")" && pwd)"
exec ffmpeg -re -stream_loop -1 -i "$DIR/uji-1080p.mp4" \
  -c:v copy -c:a aac -f flv "$URL"
