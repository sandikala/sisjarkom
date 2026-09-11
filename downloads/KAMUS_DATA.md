# Kamus data & interpretasi — SJK-TRM Web v1.0

Basis: Research_Data_Capture.xlsx, Panduan Pembelajaran Research-Ready, Modul Praktikum Research-Ready, dan Pilot Runbook v1.0 tanggal 8 September 2026.

## Tingkat data

| Tabel | Satu baris mewakili | Akses |
|---|---|---|
| sjk_staff | Akun asisten/admin yang diizinkan | User membaca profil sendiri; perubahan melalui pengelola database. |
| sjk_protocol | Protokol satu semester, singleton id=1 | Staff membaca; admin mengubah kendali. |
| sjk_participants | Peserta pseudonim | Staff; perubahan diaudit. |
| sjk_assignments | Kelas × kelompok × modul M12–M15 | Staff membaca; admin membekukan sekali melalui fungsi. |
| sjk_events | Peserta × tugas × percobaan / revisi | Staff dengan consent aktif; insert, tanpa update/delete langsung. |
| sjk_scoring | Artefak × assessor | Pembuat dan admin membaca; satu skor per pasangan. |
| sjk_audit | Perubahan registry/protokol dan penambahan event/scoring | Admin saja. |

Semua tabel riset menolak akses anonim. Akun Auth tanpa daftar staff tidak memperoleh akses walaupun mengetahui endpoint API.

## Pemetaan workbook terdahulu

| Sheet workbook | Implementasi web |
|---|---|
| Participants | Registry peserta + skor pre/post/common/transfer. |
| Randomization | Assignment beku per kelompok/modul; baris peserta yang identik dideduplicasi saat impor. |
| Events | Entri event + ekspor SJK_Events.csv. |
| Fidelity | Objek `fidelity` pada event, ditambah `fidelity_deviation`. |
| Telemetry_QC | Field ringkasan telemetry pada event; impor header template tersedia. |
| Double_Scoring | Satu skor per assessor/artefak; join berdasarkan Artifact ID saat analisis. |
| Fault_Bank | Tetap pada release protokol/gateway terdahulu; web menyimpan fault ID yang sudah dibekukan. |
| Data_Dictionary | Dokumen ini. |

## Field event

| Field | Makna / aturan |
|---|---|
| event_id | ID unik, 4–100 karakter huruf besar/angka/titik/underscore/garis; satu per percobaan. |
| participant_id | P diikuti 5–11 karakter acak. Tidak memakai nama atau NIM. |
| class_code / group_id | E1/E2/BAU dan kelompok; harus cocok dengan registry. |
| module_id | Bilangan 1–16. |
| task_id / fault_id | Versi tugas/form dan identitas fault; M12–M15 harus cocok assignment. |
| condition | Adaptive, Standard, Baseline, CommonAssessment, Transfer. |
| sequence | S1/S2 untuk M12–M15; kosong untuk modul lainnya. |
| device_id / modality | Pseudonim perangkat dan Raspberry Pi/Laptop/VM/Simulation. Catat perbedaan modality pada analisis. |
| start_ts | Saat tugas/fault dinyatakan mulai. |
| diagnosis_ts | Saat diagnosis eksplisit pertama; kosong jika tidak tersedia. |
| resolution_ts | Saat verification test menunjukkan pulih; hanya bila berhasil dalam window. |
| end_ts | Akhir window outcome. |
| debrief_ts | Debrief selesai, setelah end_ts. |
| window_s | Durasi yang ditetapkan: 600 pada M12–M16; baseline M8/M11 480. |
| success | Boolean; benar hanya jika verification test lolos dalam window. |
| ttr_s | Turunan server: resolution−start dalam detik; kosong bila gagal. |
| followup_s | Waktu pengamatan: TTR untuk berhasil; min(window, end−start) untuk gagal. |
| censored | `true` bila tidak resolved; validity flag tetap menentukan kelayakan analisis. |
| diagnosis_first | Pernyataan diagnosis awal, maksimal 3.000 karakter. |
| diagnosis_correct | 0/1 atau kosong. Setara first_diagnosis_correct pada panduan. |
| hint_count | Cue yang diterima dalam window. Standard/Transfer harus nol untuk event valid. |
| assistant_intervention | Jumlah intervensi manusia dalam window; valid primary event mensyaratkan nol. |
| sa_l1 / sa_l2 / sa_l3 | Perception/comprehension/projection, 0–2 atau missing dengan alasan. |
| fidelity | Sepuluh flag boolean sesuai checklist workbook. |
| fidelity_deviation | Alasan deviasi, telemetry gagal, SA missing, atau insiden. |
| event_status | VALID / VALID_NO_TELEMETRY / TECHNICAL_INVALID / PROTOCOL_INVALID. |
| expected_records / observed_records | Expected >0; observed unik 0–expected; keduanya kosong jika tidak diukur. |
| completeness_pct | Turunan observed/expected ×100, kosong jika tidak ada QC. |
| cpu_pct / ram_pct | Rata-rata teknis dalam window, 0–100. Tidak merekam daftar proses pribadi. |
| rtt_ms / packet_loss_pct | RTT dan kehilangan paket dari pengukuran lab yang didefinisikan. |
| throughput_mbps | Mbps, bukan MB/s. Hasil storage MB/s dikonversi/ditandai sebelum dibandingkan. |
| latency_p50_ms / latency_p95_ms | Latensi sensing/transport, bukan RTT. p95 tidak lebih kecil daripada p50. |
| agent_overhead_pct | Overhead sesuai metode paired logger-on/off pada pilot. Definisi/metode harus dibekukan. |
| service_state | up/down/degraded/not_measured. |
| protocol_version / dashboard_version | Versi protokol yang dibekukan dan aplikasi pencatatan. |
| assessor_id / created_at | ID akun pencatat dan timestamp penerimaan server. |
| supersedes_id / revision_reason | Revisi menunjuk event sebelumnya; alasan wajib. |

NOT_ENROLLED pada workbook dipetakan ke registry tanpa consent aktif. Absen/withdrawal tidak dibuat sebagai event gagal. Dengan demikian denominator tidak bertambah karena ketidakhadiran atau penolakan ikut riset.

## Ringkasan dashboard

- Menampilkan record aktif, yaitu yang tidak memiliki record pengganti. Record awal tetap tersimpan.
- Penyelesaian = event berhasil / event dengan status VALID atau VALID_NO_TELEMETRY.
- Ketepatan diagnosis = diagnosis tepat / diagnosis yang dinilai pada event valid. Missing dikeluarkan dari denominator.
- Median TTR hanya memakai event valid yang berhasil. Ini statistik bersyarat dan dapat terkena bias seleksi; bukan estimasi efek perlakuan.
- Perbandingan Adaptive/Standard hanya E1/E2 pada M12–M15 dan mengikuti filter pengguna.
- QC rata-rata hanya status VALID, bukan estimasi completeness seluruh sistem; jumlah status tanpa telemetry dilaporkan terpisah.
- Perubahan pre–post dihitung hanya pada pasangan yang memiliki keduanya dan mengikuti filter kelas.
- Tabel event menampilkan 100 record terbaru; ekspor menyertakan seluruh record yang telah dimuat sesuai filter. Pemuatan API memaginasi 1.000 baris dan menolak pemuatan parsial jika melampaui 100.000 baris.

## Analisis lanjutan

Gunakan model yang mempertimbangkan event bersarang dalam peserta/kelompok dan tugas. TTR dapat memerlukan model survival/AFT untuk censoring; success dan diagnosis menggunakan model biner yang sesuai; hint count memakai model count. Transfer M16 dianalisis dengan baseline sesuai preregistrasi. E1/E2 versus BAU adalah analisis sekunder dengan keterbatasan perbedaan pengampu.

Web tidak menghitung p-value, effect size kausal, ICC, kappa, atau klaim validitas instrumen. Ekspor menyediakan data untuk analisis tersebut. Preregistrasi, expert review, pilot, dan aturan missingness tetap mengikuti protokol terdahulu.

Ekspor CSV menetralkan teks yang dapat dibaca sebagai formula spreadsheet dengan awalan apostrof. Kolom JSON fidelity dapat diratakan menjadi kolom boolean pada tahap cleaning; raw data dipertahankan.
