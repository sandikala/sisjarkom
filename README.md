# SJK-TRM · Ruang Belajar & Riset

Web siap unggah untuk `https://sandikala.github.io/sjktrm/`, berdasarkan perangkat pembelajaran dan riset SJK-TRM Research-Ready v1.0.

## Dua menu utama

1. **Pembelajaran mahasiswa** — 16 pertemuan, materi, tujuan, tugas pendahuluan, langkah praktikum lengkap, 48 soal formatif, checkpoint mandiri, lembar kerja/CSV, dan eksplorasi interaktif.
2. **Dashboard riset** — login asisten, registry pseudonim, assignment beku, timing/diagnosis/outcome, SA, fidelity, telemetry QC, koreksi record dengan jejak audit, scoring independen, filter, rekap, dan ekspor CSV.

Eksplorasi: kapasitas storage, Amdahl, buffer frame, PCM/bilangan, simulator GPIO, diagnosis konektivitas, topologi, susunan T568B, protokol, subnetting, VLSM, dan kapasitas streaming. Semua simulasi dilabeli sebagai latihan, bukan data penelitian.

## Mulai

1. Unggah isi ZIP agar `index.html` berada di root repository `sandikala/sjktrm`.
2. Atur GitHub Pages ke branch `main`, folder `/(root)`.
3. Ikuti [panduan hosting](downloads/PANDUAN_HOSTING.md) untuk menjalankan `backend/schema.sql`, membuat akun, dan mengisi dua nilai publik Supabase di `config.js`.

Web mahasiswa dan demo riset berfungsi sebelum backend dikonfigurasi. Data beberapa asisten baru tersimpan bersama setelah Supabase dan akun diaktifkan. Tidak ada akun default, password yang ditanam, atau penyimpanan riset semu melalui localStorage.

## Berkas penting

| Berkas | Kegunaan |
|---|---|
| index.html | Halaman utama dengan tepat dua menu utama. |
| config.js | URL Supabase, publishable key, dan tautan paket media. |
| assets/course.json | Konten 16 pertemuan yang dapat diedit. |
| assets/learn.js | Interaksi pembelajaran dan kuis. |
| assets/research.js | Formulir dan rekap asisten. |
| assets/core.js | Validasi data, statistik deskriptif, CSV, subnetting. |
| assets/api.js | Auth Supabase dan akses data dengan token pengguna. |
| assets/style.css | Tampilan responsif, keyboard, serta gaya cetak. |
| backend/schema.sql | Tabel, constraints, fungsi, audit, grants, RLS. |
| backend/verify_access.sql | Pengujian akses di Supabase uji; fixture di-rollback. |
| downloads/ | Panduan hosting/asisten, kamus data, template, serta utilitas media. |
| tests/core.test.js | Pengujian logika penting. |
| VALIDASI.md | Hasil pemeriksaan dan batas yang belum diuji. |

## Sumber dan adaptasi

Sumber yang digunakan:

- `00_Panduan_Pembelajaran_SJK_TRM_Research_Ready.docx`
- `01_Modul_Praktikum_SJK_TRM_Research_Ready.docx`
- `Research_Data_Capture.xlsx`
- `02_Panduan_Teknis_Pilot_SJK_TRM_Research_Ready.docx`
- `Sumber_Panduan.md`
- `Sumber_Modul_Praktikum.md` (format asli blok kode dan tabel)
- `SJK_TRM_Media_Uji_v1.0.zip`

Struktur semester dan desain riset dipertahankan. Kuis formatif, kalkulator, dan simulator merupakan tambahan web. Kuis publik tidak dipakai sebagai instrumen pre/post/transfer. Penelitian tetap memerlukan tahapan validasi yang ditetapkan dalam protokol.

Media uji besar dibagikan sebagai ZIP terpisah. Upload sebagai GitHub Release asset, lalu masukkan URL unduhan aktual pada `mediaDownloadUrl`. Jangan memasukkan video 4K besar atau data peserta ke repository web.

Penjelasan koreksi teknis terdapat pada [catatan lab](downloads/CATATAN_TEKNIS_LAB.md). Source modul akademik ditampilkan di menu mahasiswa; assignment peserta dan data riset berasal dari database dengan akses terkontrol.

## Pengembangan

Tidak perlu npm install. Untuk paket unduhan, jalankan server lokal dari folder `index.html`:

```bash
python3 -m http.server 8000
```

Jalankan pengujian dengan Node:

```bash
node --test tests/core.test.js
```

Pada checkout authoring, web berada pada `dist/`. ZIP siap unggah menempatkan isi `dist/` di root; file lain yang diperlukan turut disertakan.
