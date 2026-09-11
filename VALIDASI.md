# Pemeriksaan paket SJK-TRM Web v1.0

Paket disiapkan pada 8 September 2026 untuk GitHub Pages `sandikala/sjktrm`.

## Pemeriksaan yang telah dilakukan

- Sintaks JavaScript aplikasi, pembelajaran, riset, autentikasi/API, dan renderer konten: lolos `node --check`. Modul logika inti dimuat dan diuji oleh Node.
- 12 pengujian logika: seluruhnya lolos. Mencakup S1/S2, IPv4, VLSM, timestamp, TTR/censoring, QC, fidelity, koreksi record, denominator data missing, ekspor/parser CSV, dan kelengkapan kurikulum.
- 16 modul dan 48 soal formatif tersedia. Seluruh 107 bagian akademik memiliki format terstruktur, termasuk 38 blok perintah yang mempertahankan newline/indentasi dari sumber Markdown.
- 21 referensi asset/import/unduhan diperiksa dan ditemukan. Jalur bersifat relatif dan navigasi detail menggunakan hash untuk project Pages `/sjktrm/`.
- Media standar memakai ZIP asli terdahulu. Berkas utama tidak dikompresi ulang atau diganti. Hanya utilitas/checksum/petunjuk media yang disertakan di paket web.
- Peninjauan implementasi memastikan dataset demo terpisah dari API, sesi tidak memakai service-role key, izin akses diterapkan pada database, raw event tidak memiliki grant update/delete, dan koreksi menyimpan referensi ke record lama.

## Batas pemeriksaan

- Belum dipublikasikan ke GitHub. Akun GitHub pengguna tidak diubah.
- Proyek Supabase dan akun pengguna belum dikonfigurasi; schema SQL, koneksi cloud, login lintas akun, dan pengujian RLS belum dieksekusi pada server nyata. Script `backend/verify_access.sql` disediakan untuk proyek uji dengan pgTAP.
- Tidak dilakukan pengujian browser visual/interaksi maupun pada smartphone fisik. Layout memiliki aturan responsif, kontrol keyboard, label form, dan gaya cetak, tetapi klaim hasil uji visual lintas perangkat tidak dibuat.
- Tidak dilakukan uji lab dengan Raspberry Pi, GPIO, crimping, DHCP, routing, Samba, NGINX, atau gateway riset. Jalankan rehearsal sesuai runbook sebelum kelas.
- Ini implementasi pencatatan dan rekap; bukan validasi ilmiah instrumen atau bukti efek pembelajaran. Tidak ada hasil penelitian nyata pada paket awal.

## Sebelum pengumpulan data nyata

Jalankan pemeriksaan dua akun/dua perangkat pada proyek uji sebagaimana panduan hosting, termasuk penolakan akun tidak terdaftar, assignment beku, event timeout, koreksi record, missing telemetry, withdrawal, dan ekspor. Gunakan database produksi yang bersih dari fixture/demo setelah uji selesai.
