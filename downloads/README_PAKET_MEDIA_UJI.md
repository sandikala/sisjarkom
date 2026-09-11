# Paket Media Uji SJK-TRM v1.0

Paket ini dibuat khusus untuk praktikum **Sistem dan Jaringan Komputer — Sarjana Terapan Teknologi Rekayasa Multimedia**. Semua konten visual/audio bersifat sintetis sehingga aman didistribusikan dan dapat dipakai ulang untuk eksperimen lintas kelas.

## File utama

| File | Spesifikasi | Kegunaan utama |
|---|---|---|
| `uji-1080p.mp4` | H.264, 1920×1080, 30 fps, 60 s, AAC stereo 48 kHz | M1–M3 encoding/memory; M6 playback; M12 UDP/TCP streaming; M15 RTMP/HLS |
| `uji-4k.mp4` | H.264, 3840×2160, 30 fps, 30 s, AAC stereo 48 kHz | M3 memory/proxy; M6 storage/load |
| `uji-audio.wav` | PCM signed 16-bit LE, 48 kHz, stereo, 60 s | M4 header/bit depth; M7 GPIO audio trigger |
| `uji-gambar.png` | PNG, 1920×1080, RGB 8-bit | M4 magic number, grayscale/RGB8/subsampling exercises |
| `uji-transfer-32MiB.bin` | 32 MiB deterministic pseudo-random | quick connectivity/Samba sanity check |

## Berkas transfer besar

Modul membutuhkan transfer 500 MB dan pada M6 menyebut beban salin besar. Jangan distribusikan file multi-GB melalui LMS. Buat lokal sekali:

```bash
chmod +x generate-transfer-files.sh
./generate-transfer-files.sh ~/praktikum/media
```

Hasil:
- `uji-transfer-500MiB.bin` — untuk M8/M15/M16.
- `uji-transfer-2GiB.bin` — untuk stress/throughput M6 bila storage mencukupi.

File dibuat dengan stream pseudo-random agar kompresi jaringan/storage tidak terlalu menguntungkan hasil benchmark.

## Instalasi

Salin folder ini ke setiap laptop/Raspberry Pi:

```bash
mkdir -p ~/praktikum/media
cp uji-1080p.mp4 uji-4k.mp4 uji-audio.wav uji-gambar.png ~/praktikum/media/
```

Validasi:

```bash
./verify-media.sh
sha256sum -c SHA256SUMS.txt
```

## Streaming tanpa OBS (opsional)

Jika OBS tidak tersedia, `uji-1080p.mp4` dapat dikirim berulang ke server RTMP:

```bash
./stream-to-rtmp.sh rtmp://192.168.10.11/live/kelompok1
```

## Catatan reproduksibilitas

- Video menggunakan pola sintetis bergerak `testsrc2`, sehingga mengandung detail dan motion yang memadai untuk eksperimen encoding.
- 4K dibuat dari segmen sintetis yang di-loop untuk menjaga footprint proses generasi tetap rendah; resolusi, codec, frame rate, dan durasi akhir tetap sesuai spesifikasi modul.
- Audio WAV: kanal kiri 440 Hz dan kanan 880 Hz, berguna untuk memverifikasi stereo/channel mapping.
- Jangan mengubah file utama di tengah semester. Jika file diganti, naikkan versi paket dan catat checksum baru.
