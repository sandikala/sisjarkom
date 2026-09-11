# SJK-TRM — memasang web di GitHub Pages

Target: https://sandikala.github.io/sjktrm/

Paket ini telah disiapkan untuk diunggah. Belum ada perubahan atau publikasi ke akun GitHub maupun Supabase Anda. Web memakai HTML/CSS/JavaScript statis; tidak membutuhkan npm install atau proses build untuk hosting.

## 1. Unggah web

1. Ekstrak `sjktrm-github-pages.zip`.
2. Buka atau buat repository **sjktrm** pada akun **sandikala**. Untuk GitHub Pages pada GitHub Free, gunakan repository public.
3. Pilih **Add file → Upload files**. Unggah isi hasil ekstraksi, bukan ZIP-nya. Pastikan `index.html`, `config.js`, folder `assets`, dan folder `downloads` berada langsung pada tingkat paling atas repository. Folder `backend` dan `tests` boleh disertakan; isinya hanya source/schema dan fixture sintetis.
4. Simpan ke branch `main`.
5. Buka **Settings → Pages**. Pada **Build and deployment**, pilih **Deploy from a branch**, branch **main**, folder **/(root)**, lalu **Save**.
6. Setelah proses publikasi GitHub selesai, buka https://sandikala.github.io/sjktrm/ . Menu mahasiswa langsung dapat digunakan. Menu riset menyediakan demo sebelum koneksi database diatur.

Tautan internal menggunakan hash, misalnya `#belajar/14/eksplorasi` dan `#riset/ringkasan`, sehingga pemuatan ulang tidak memerlukan aturan server khusus. Jangan membuat CNAME untuk alamat project Pages ini.

Rujukan: [Mengatur sumber publikasi GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site).

## 2. Aktifkan data bersama dengan Supabase

GitHub Pages menyajikan berkas statis. Isian beberapa asisten memerlukan penyimpanan bersama. Integrasi Supabase sudah disertakan; akun/proyek milik Anda perlu diatur satu kali.

1. Buat proyek Supabase khusus mata kuliah/semester ini.
2. Buka **SQL Editor**. Salin seluruh `backend/schema.sql`, lalu jalankan sekali. Gunakan proyek baru atau pastikan tidak ada tabel `sjk_*` sebelumnya. Jika sudah dipasang, jangan menjalankan ulang schema awal pada database berisi data.
3. Dari pengaturan API proyek, salin **Project URL** dan **publishable key**. Key `anon` lama juga didukung jika proyek Anda masih menggunakannya. **Jangan memakai `service_role`, `sb_secret_...`, atau password database.**
4. Edit `config.js` di repository. Isi hanya nilai publik berikut, pertahankan bagian lainnya:

```javascript
window.SJK_CONFIG = Object.freeze({
  supabaseUrl: "https://GANTI-PROJECT-REF.supabase.co",
  supabasePublishableKey: "GANTI-DENGAN-PUBLISHABLE-KEY",
  courseTitle: "Sistem dan Jaringan Komputer",
  protocolVersion: "v1.0",
  mediaDownloadUrl: "",
  siteBase: "https://sandikala.github.io/sjktrm/"
});
```

5. Commit perubahan. Tunggu GitHub Pages memperbarui web.

Publishable key memang digunakan di browser. Perlindungan data dilakukan dengan autentikasi, daftar asisten, grants, dan Row Level Security pada database, bukan dengan menyembunyikan tombol login. [API keys Supabase](https://supabase.com/docs/guides/getting-started/api-keys), [Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security).

## 3. Daftarkan akun dosen dan asisten

1. Pengelola membuat akun email/password di **Authentication → Users** pada Supabase. Gunakan password unik yang tidak disimpan dalam repository.
2. Daftarkan email dosen yang sudah dibuat sebagai admin. Ganti email dan nama pada contoh berikut, lalu jalankan di SQL Editor:

```sql
insert into public.sjk_staff (user_id, display_name, role)
select id, 'Dosen pengelola', 'admin'
from auth.users
where lower(email) = lower('GANTI-EMAIL-DOSEN');
```

3. Untuk setiap asisten, jalankan pola berikut dengan email akun yang benar:

```sql
insert into public.sjk_staff (user_id, display_name, role)
select id, 'Asisten praktikum 1', 'assistant'
from auth.users
where lower(email) = lower('GANTI-EMAIL-ASISTEN');
```

4. Periksa bahwa setiap perintah menghasilkan satu baris. Jika nol, akun/email belum cocok. Jangan mendaftarkan mahasiswa pada tabel staff.
5. Buka web → **Dashboard riset** → login menggunakan akun tersebut. Akun yang berhasil login tetapi tidak terdaftar sebagai staff aktif tetap ditolak. Tidak ada fasilitas pendaftaran akun bebas di web.
6. Pengelola dapat menonaktifkan pendaftaran pengguna baru pada pengaturan Auth proyek jika hanya memakai akun yang dibuat pengelola. Untuk menonaktifkan akses asisten, ubah `sjk_staff.active` menjadi `false` melalui SQL Editor.

Semua asisten aktif dapat membaca dataset mata kuliah ini dan mencatat data. Hanya admin dapat mengubah kendali protokol, membekukan assignment, atau membaca audit. Scoring independen dibaca oleh pembuatnya dan admin.

## 4. Aktifkan protokol sebelum data penelitian

1. Masuk sebagai admin. Di **Peserta & asesmen**, masukkan roster pseudonim dan status consent. Simpan pemetaan nama/NIM di tempat terpisah yang dikelola data steward.
2. Di **Protokol**, isi referensi persetujuan etik dan status kelulusan pilot. Simpan dalam keadaan pengumpulan data belum aktif.
3. Impor CSV assignment dari randomization sheet yang telah dibuat pada pekerjaan sebelumnya. Jika belum ada assignment sama sekali, peneliti perlu menjalankan randomisasi kelompok sesuai protokol terlebih dahulu. Web ini sengaja tidak mengganti hasil randomisasi yang sudah ditetapkan.
4. CSV memakai kolom `class_code,group_id,sequence,module_id,condition,fault_id`; boleh menyertakan kolom tambahan dari workbook. `module_id` menerima `12` atau `M12`. Baris per peserta dengan assignment kelompok yang identik digabung; konflik ditolak.
5. Isi seed yang benar dari lembar sumber, tinjau pratinjau, lalu klik **Bekukan assignment yang ditampilkan**. Setiap kelompok E1/E2 yang consent harus memiliki M12–M15 dengan satu sequence konsisten. BAU tidak masuk randomisasi.
6. Setelah roster, pilot, ethics, dan assignment lengkap, aktifkan pengumpulan data riset. Pembelajaran mahasiswa tidak bergantung pada status ini.

Setelah freeze, kelompok, kelas, seed, dan versi protokol tidak dapat diubah melalui web. Jangan mengubah assignment setelah melihat hasil. Amendment atau kohort baru harus dikelola peneliti melalui prosedur versi/migrasi tersendiri.

## 5. Sediakan media uji dari paket terdahulu

Paket `SJK_TRM_Media_Uji_v1.0.zip` disediakan terpisah (sekitar 218 MiB). Gunakan berkas asli agar checksum sama. Paket web ini sudah berisi petunjuk, checksum, dan skrip bantu media.

1. Buka bagian **Releases** di repository `sjktrm`, lalu buat release untuk media praktikum.
2. Lampirkan ZIP media asli sebagai release asset dan publikasikan release sesuai kebutuhan kelas.
3. Salin alamat unduh asset yang benar-benar dibuat.
4. Masukkan alamat HTTPS itu pada `mediaDownloadUrl` di `config.js`.
5. Setelah commit, tombol **Paket media uji** pada menu mahasiswa akan menampilkan tautan unduhnya.

Jangan mengunggah video 4K asli langsung sebagai file repository: ukurannya sekitar 134 MiB. GitHub membatasi file repository biasa di atas 100 MiB, dan upload file melalui browser di atas 25 MiB. Release assets lebih sesuai untuk paket media. [Batas file GitHub](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github), [GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases).

## 6. Verifikasi sebelum digunakan kelas

- Buka halaman mahasiswa tanpa login: 16 modul, kuis, dan kalkulator harus tersedia.
- Coba demo riset: pastikan label DEMO terlihat dan data tidak dianggap hasil penelitian.
- Login asisten terdaftar dari dua perangkat. Catat satu event uji di proyek uji, lalu tekan **Muat data bersama** pada perangkat kedua dan periksa record yang sama.
- Gunakan akun Auth yang tidak tercantum di `sjk_staff`: akses riset harus ditolak.
- Periksa timeout, record koreksi, ekspor, dan status penarikan consent pada proyek uji.
- Aktifkan pgTAP dan jalankan `backend/verify_access.sql` pada proyek uji. Script melakukan rollback seluruh fixture.

Validasi logika lokal sudah dijalankan pada paket ini; koneksi Supabase nyata dan pengujian akses lintas akun belum dijalankan karena proyek serta akun Anda belum tersedia.

## Menjalankan dari laptop sebelum upload

Dari folder yang berisi `index.html`:

```bash
python3 -m http.server 8000
```

Buka `http://localhost:8000`. Jangan membuka `index.html` dengan klik ganda karena browser membatasi pemuatan modul/JSON melalui `file://`. Penggunaan Supabase tetap memerlukan internet. Fonts dapat beralih ke font sistem saat sumber font eksternal tidak tersedia.

## Kendala umum

| Gejala | Periksa |
|---|---|
| 404 pada alamat Pages | Repository `sjktrm`, branch `main`, source `/(root)`, dan `index.html` benar-benar di root. |
| Tampilan tanpa gaya / materi kosong | Folder `assets` dan `downloads` ikut diunggah; kapitalisasi nama file tidak berubah. |
| Tombol login belum aktif | Dua nilai Supabase pada `config.js` masih kosong, atau Pages belum memperbarui commit. |
| Login berhasil tetapi akses ditolak | Akun belum masuk `sjk_staff`, email salah, atau `active=false`. |
| Event tidak bisa disimpan | Consent, protokol aktif, assignment, timing, fidelity, dan validitas harus sesuai. Baca pesan di bawah form. |
| Data asisten lain belum terlihat | Tekan Muat data bersama. Ini refresh eksplisit, bukan koneksi telemetry langsung. |
| Data hilang setelah mencoba demo | Demo hanya berlangsung dalam sesi halaman dan tidak masuk database. |
| Koneksi gagal saat form terisi | Isian dipertahankan; perbaiki koneksi dan kirim lagi, atau unduh draft sebelum menutup. |

Jangan masukkan data peserta, ekspor riset, token sesi, password, atau file database ke repository GitHub Pages.
