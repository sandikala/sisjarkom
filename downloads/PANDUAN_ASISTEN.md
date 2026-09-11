# Panduan asisten — SJK-TRM Web v1.0

## Sebelum sesi

1. Login pada menu Dashboard riset. Pastikan tidak ada label MODE DEMO.
2. Tekan Muat data bersama. Periksa peserta, consent, kelompok, modul, dan assignment.
3. Siapkan alat, media yang sama, jam sinkron, serta baseline restore sesuai runbook pilot.
4. Pastikan protokol aktif. Materi, nilai, dan bantuan akademik tetap diberikan kepada peserta yang tidak ikut riset.

## Selama praktikum

Pola umum: Demo → Do → Debug → Document. Checkpoint mahasiswa di menu pembelajaran hanya pengingat mandiri; verifikasi akademik dilakukan asisten dengan demonstrasi dan penjelasan. Nilai reguler mengikuti rubrik 5 aspek skala 0–4 dan tidak ditentukan oleh window riset.

Untuk 3–6 Raspberry Pi, rotasikan kegiatan fisik, konfigurasi/SSH, simulasi laptop, dan dokumentasi. Modul GPIO memerlukan aksesori; bila belum tersedia, simulator web dapat melatih konsep dan modus simulasi harus dicatat.

## Mencatat satu event

1. Pilih peserta dan modul di Entri data. Kelas/kelompok berasal dari registry; M12–M15 mengambil condition, sequence, dan fault dari assignment beku.
2. Event ID harus unik per percobaan. Cocokkan Event ID ini dengan log gateway. Pilih Task ID, Device ID pseudonim, dan modus Raspberry Pi/Laptop/VM/Simulation yang benar.
3. Klik Mulai window pada aba-aba yang sama dengan logger. M12–M16 memakai 600 detik; baseline M8/M11 memakai 480 detik. Tombol tidak menjalankan fault atau logger secara otomatis.
4. Saat peserta pertama kali menyebut diagnosis, klik Catat diagnosis pertama, lalu tulis pernyataannya apa adanya. Jika tidak ada diagnosis, biarkan timestamp dan skor diagnosis kosong; jelaskan missingness.
5. Setelah verification test membuktikan sistem pulih dalam window, klik Catat berhasil pulih. Tombol mengisi resolution dan akhir window; timer berhenti. Jika belum pulih sampai batas waktu, akhiri window dan pilih Belum selesai/timeout. Timer memberi pengingat; tidak otomatis menyimpan outcome.
6. Window berakhir sebelum SA. Beri probe L1, L2, L3; skor masing-masing 0–2, atau biarkan kosong dengan alasan. Debrief dilakukan setelahnya dan waktunya dicatat terpisah.
7. Verifikasi checklist fidelity. Bantuan manusia pada window perlu dilaporkan; bukan disembunyikan dengan menurunkan hint count. Standard/Transfer tidak menerima adaptive cue. Safety/kerusakan diutamakan lalu validitas event ditinjau sesuai penyebab.
8. Masukkan ringkasan telemetry atau impor satu baris QC CSV dengan Event ID yang persis sama. Jangan unggah packet payload, URL pribadi, password, isi media, atau full shell history.
9. Tentukan event status, tulis deviasi/missingness, lalu Simpan data riset. Pesan sukses berarti server telah mengembalikan record. Koneksi gagal mempertahankan isian di form.
10. Asisten lain menekan Muat data bersama untuk melihat record terbaru.

## Timing dan timeout

- `ttr_s` hanya terisi pada event berhasil, dari resolution dikurangi start.
- Event timeout menyimpan `ttr_s` kosong, `censored=true`, dan waktu pengamatan `followup_s`.
- `end_ts` adalah akhir window outcome, bukan waktu laporan selesai.
- Event berakhir dini karena alat rusak diberi status TECHNICAL_INVALID dan alasan; bukan timeout valid.
- Timestamp memakai zona waktu browser saat diisi, lalu disimpan sebagai UTC.

## Koreksi data

Klik Koreksi pada record. Beri ID record baru dan alasan perubahan minimal 10 karakter. Record sebelumnya tetap ada, record koreksi menautkannya melalui `supersedes_id`, dan hanya versi terkini dihitung pada ringkasan. Jangan memakai koreksi untuk menambah percobaan baru; percobaan baru memiliki Event ID sendiri tanpa `supersedes_id`.

Jika dua asisten mengoreksi record yang sama bersamaan, database menerima satu revisi dan menolak revisi bercabang. Muat ulang sebelum mencoba lagi.

Perubahan registry peserta dicatat dalam audit database. Data steward menangani withdrawal/retensi sesuai keputusan institusi. Perubahan consent menyembunyikan event peserta dari akses dataset aktif; bukan perintah penghapusan otomatis semua backup.

## Telemetry

Alur sebelumnya tetap digunakan: agent → Mosquitto/MQTT → collector SQLite/CSV → dashboard intervensi lokal. Web GitHub Pages ini merupakan pencatatan asisten dan dashboard rekap. Tidak ada sambungan MQTT atau proses fault injection dari web.

Untuk QC, gunakan jendela `[start_ts, end_ts)` dengan jadwal sampling yang dibekukan. Jika sampel pertama direncanakan tepat di start dan interval 5 detik, expected = ceil(durasi/5). Jika phase sampling berbeda, hitung expected dari jadwal collector aktual. Hitung observed dari sampel unik, hilangkan duplikat, jangan memasukkan sampel di luar window. Completeness = observed/expected ×100. Latensi p50/p95 memerlukan timestamp sumber dan penerimaan pada clock yang tersinkron, bukan pengurangan jam dari mesin yang tidak sinkron.

`VALID` mensyaratkan completeness ≥95%. Outcome perilaku yang tetap sah saat telemetry tidak memadai menggunakan `VALID_NO_TELEMETRY`. Overhead logger tetap dipilotkan; tidak ada ambang universal yang dibuat oleh web.

## Scoring independen

Gunakan Artifact ID yang sama untuk kedua assessor. Masing-masing login dengan akun sendiri dan memasukkan skor sendiri. Asisten hanya melihat skor miliknya; admin melihat pasangan skor. Isi skor agregat/adjudikasi pada registry setelah penilaian independen selesai agar tidak memberi petunjuk pada assessor kedua. Siapkan artefak dengan ID pseudonim sesuai upaya pembutaan pada protokol.

Form ini mencatat satu skor per assessor/artefak. Jika ada salah ketik pada scoring, minta data steward melakukan amendment yang terdokumentasi. Jangan menggandakan Artifact ID untuk menyamarkan koreksi. Analisis ICC atau weighted kappa dan confidence interval dilakukan di perangkat analisis; tidak dihitung otomatis oleh web.

## Setelah sesi

- Restore fault dan konfigurasi lab sesuai baseline.
- Selesaikan rekap akademik dalam 1×24 jam sesuai panduan.
- Ekspor CSV riset ke penyimpanan terkontrol, bukan repository public.
- Shutdown Raspberry Pi dengan benar dan rapikan alat.
- Keluar dari dashboard pada komputer bersama.

Instrumen pre/post/transfer memerlukan expert review dan pilot sesuai protokol terdahulu. Kuis mahasiswa di web adalah latihan baru, bukan instrumen penelitian yang telah divalidasi.
