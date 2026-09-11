# Catatan teknis adaptasi web

Materi web menggunakan urutan, tujuan, langkah, dan rubrik dari 16 modul Research-Ready v1.0. Ringkasan konsep, kuis formatif, dan simulator ditambahkan untuk latihan. Beberapa istilah/perintah dikoreksi agar pemaknaan lebih tepat.

## Media dan satuan

- Standar media mengikuti modul dan paket uji terbaru: 1080p 60 detik, 4K 30 detik, audio PCM 48 kHz/16-bit/stereo 60 detik, PNG 1920×1080. Ringkasan panduan awal yang menyebut klip 10 detik tidak dijadikan standar file.
- MB dan GB adalah satuan desimal; MiB dan GiB adalah biner. Frame 4K RGB 8-bit = 24.883.200 byte = 23,73 MiB.
- `scale=640:-2` pada video 16:9 menghasilkan 640×360, bukan 480p. Gunakan workload identik saat membandingkan laptop dan Pi.
- Pada uji thread encoding, tempatkan `-threads:v` sebagai opsi output setelah input dan codec. Contoh Linux:

```bash
ffmpeg -i ~/praktikum/media/uji-1080p.mp4 -c:v libx264 -threads:v 2 -preset medium -t 30 hasil-thread2.mp4
```

Jangan menyimpulkan pengaruh jumlah thread decoder sebagai pengaruh encoder. [Dokumentasi FFmpeg](https://ffmpeg.org/ffmpeg.html).

## Sistem operasi

`lscpu`, `free`, `lsblk`, `ip`, dan GNU `/usr/bin/time -f` merupakan contoh lingkungan Linux. macOS memiliki perangkat diagnostik berbeda; gunakan System Information/Activity Monitor atau jalankan tahap Linux di VM. PowerShell memakai perintah Windows pada modul. Jangan menganggap semua perintah Linux tersedia pada macOS.

Image Raspberry Pi OS baru menggunakan `rpicam-still`; nama tool mengikuti versi image yang digunakan. [Dokumentasi kamera Raspberry Pi](https://www.raspberrypi.com/documentation/computers/camera_software.html).

## Raspberry Pi bersama dan aksesori

- Benchmark CPU/storage bergantian; beberapa mahasiswa yang melakukan encoding bersamaan pada Pi yang sama menjadi confound.
- Jangan melakukan `drop_caches` global pada Pi yang sedang dipakai kelompok lain. Gunakan file uji lokal dan direct I/O jika filesystem mendukung, lalu laporkan caching serta batas metode. Jangan mengarahkan output `dd` ke device disk mentah.
- VM menggantikan sebagian besar latihan Linux/jaringan. VM tidak menggantikan pengujian kabel, GPIO, dan alat fisik. Simulator tombol pada web hanya demonstrasi konsep.
- Breadboard, tombol, LED/resistor, sensor, webcam, mikrofon, switch, dan LAN tester mengikuti ketersediaan lab; bukan diasumsikan sudah termasuk inventaris minimum pengguna.

## M13–M14: dua subnet memerlukan dua jalur nyata

Pemberian dua alamat saja tidak membuktikan isolasi. Gunakan dua interface yang benar-benar berada di segmen berbeda, atau dua jaringan host-only terpisah pada VM. Untuk Pi, interface kedua bisa USB-Ethernet atau jaringan WLAN yang telah disiapkan pengelola; `wlan0` tidak otomatis menjadi access point.

1. Dengan konsol lokal/asisten, identifikasi interface dan nama koneksi menggunakan `ip -br address` dan `nmcli connection show`.
2. Catat konfigurasi awal, rute, forwarding, serta ruleset. Siapkan restore sebelum mengubah koneksi yang dipakai SSH.
3. Untuk contoh implementasi dua segmen pada handout: produksi `192.168.20.0/26`, Pi produksi `192.168.20.1/26`; tamu `192.168.20.192/27`, Pi tamu `192.168.20.193/27`. Berikan masing-masing klien alamat dan gateway sesuai segmennya. Pastikan interface kedua dikonfigurasi juga, bukan hanya eth0.
4. Aktifkan forwarding pada router lab lalu uji routing dasar. NAT bukan syarat komunikasi dua subnet yang memiliki rute balik benar. Jika NAT diperlukan untuk uplink, sesuaikan `oifname` dengan interface uplink yang benar.
5. Terapkan kebijakan tamu→produksi dan uji matriks akses. Jangan menghubungkan DHCP percobaan ke jaringan kampus.
6. Pulihkan konfigurasi setelah sesi sesuai snapshot awal; jangan membiarkan forwarding atau aturan eksperimen berjalan tanpa pengelola.

Hasil kalkulator VLSM untuk soal 50/25/12/6/6 host mengalokasikan tamu ke `192.168.20.64/27`. Itu adalah jawaban alokasi berurutan yang berbeda dari contoh implementasi dua segmen `.192/27` pada handout. Pilih satu IP plan untuk implementasi dan gunakan secara konsisten; jangan mencampurkan keduanya. Host requirement harus mencakup alamat gateway.

## M15–M16: akses tamu ke stream, bukan ke aset

Kriteria terperinci M16 dipakai untuk mengatasi kalimat ambigu pada ringkasan panduan awal: tamu memperoleh DHCP dan menonton streaming, tetapi ditolak dari folder aset produksi. Penguji berpindah ke segmen produksi untuk menguji transfer aset.

Pilihan desain untuk lab: server streaming ditempatkan pada segmen layanan yang dapat dijangkau tamu, atau berikan allow rule yang sempit dari tamu ke IP/port layanan streaming yang ditetapkan sebelum aturan drop produksi. Jangan mengizinkan Samba produksi kepada tamu hanya agar demo terlihat berhasil. Uji juga koneksi balasan dan kebijakan input bila layanan berada pada router sendiri; chain forwarding tidak mengatur trafik yang ditujukan ke router.

RTMP memakai listener yang harus benar-benar terbuka. `systemctl active` saja tidak membuktikan aplikasi sehat. Periksa `nginx -t`, listener, log yang diizinkan, dan playback klien.

HLS tidak otomatis diputar oleh semua browser ketika URL `.m3u8` dibuka. Untuk praktikum dasar, gunakan VLC atau pemutar yang memang mendukung HLS. Halaman GitHub Pages HTTPS tidak dipakai untuk menanam player yang mengakses server HTTP lokal; mixed-content dan keterjangkauan jaringan akan menjadi kendala. Uji layanan lokal langsung dari laptop lab sesuai modul.

## Penelitian

Bank fault, skrip injeksi, dashboard intervensi, dan restore tetap mengikuti release gateway serta pilot runbook terdahulu. Web tidak menjalankan shell, mengubah jaringan, atau mengirim fault ke Raspberry Pi.

Asisten perlu melakukan rehearsal pada perangkat nyata sebelum semester. Perintah, nama interface, service, dan parameter lab harus dibekukan bersama protokol; koreksi kecil handout bukan bukti bahwa eksperimen telah dipilotkan.
