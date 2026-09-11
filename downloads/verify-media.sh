#!/usr/bin/env bash
set -euo pipefail
DIR="${1:-$(cd "$(dirname "$0")" && pwd)}"
for f in uji-1080p.mp4 uji-4k.mp4 uji-audio.wav uji-gambar.png; do
  test -f "$DIR/$f" || { echo "MISSING: $f"; exit 1; }
done
printf '\n=== uji-1080p.mp4 ===\n'
ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,width,height,r_frame_rate,pix_fmt -show_entries format=duration,size -of default=nw=1 "$DIR/uji-1080p.mp4"
printf '\n=== uji-4k.mp4 ===\n'
ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,width,height,r_frame_rate,pix_fmt -show_entries format=duration,size -of default=nw=1 "$DIR/uji-4k.mp4"
printf '\n=== uji-audio.wav ===\n'
ffprobe -v error -select_streams a:0 -show_entries stream=codec_name,sample_rate,channels,bits_per_sample -show_entries format=duration,size -of default=nw=1 "$DIR/uji-audio.wav"
printf '\n=== uji-gambar.png ===\n'
ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,width,height,pix_fmt -of default=nw=1 "$DIR/uji-gambar.png"
printf '\n=== SHA-256 ===\n'
sha256sum "$DIR"/uji-1080p.mp4 "$DIR"/uji-4k.mp4 "$DIR"/uji-audio.wav "$DIR"/uji-gambar.png
