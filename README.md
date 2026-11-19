# Mobile Inventaris Stockflow

Aplikasi mobile inventaris barang dan aset terintegrasi dengan **Stockflow Backend API** ([Dokumentasi API](https://stokflow-be.vercel.app/docs#/)).

---

## 🚀 Alur Kerja Git & Percabangan (Branching Strategy)

Repository ini menerapkan arsitektur percabangan dua tingkat standar SIM-SARPRAS:

| Branch | Fungsi | Proteksi |
|---|---|---|
| `main` | Production & Official Releases | **Protected** (Wajib PR, Review, & CI pass. Direct push dilarang). |
| `dev` | Active Development Branch | **Default working branch** untuk pengerjaan fitur harian. |
| `feature/*` | Cabang fitur baru / perbaikan | Dibuat dari `dev`, dimerge kembali ke `dev` via Pull Request. |

### Panduan Singkat Kontribusi:
1. Pastikan Anda berada di branch `dev` sebelum mulai:
   ```bash
   git checkout dev
   git pull origin dev
   ```
2. Buat cabang baru untuk fitur/perbaikan:
   ```bash
   git checkout -b feat/nama-fitur
   ```
3. Lakukan commit dengan format [Conventional Commits](https://www.conventionalcommits.org/):
   ```bash
   git commit -m "feat(auth): implementasi login jwt dengan refresh token"
   ```
4. Buka Pull Request menuju branch `dev`.
5. Rilis ke produksi dilakukan dengan membuat Pull Request dari `dev` ke `main`.

---

## 🛠️ Konvensi Commit

- `feat:` Penambahan fitur baru
- `fix:` Perbaikan bug
- `refactor:` Perubahan struktur kode tanpa mengubah fungsi
- `perf:` Peningkatan performa
- `test:` Penambahan atau pembaruan unit/widget test
- `chore:` Pemeliharaan dependensi, konfigurasi CI/CD

---

## 🔒 Konfigurasi Keamanan

- Berkas `.env` dan kredensial rahasia (keystore, sertifikat) tidak boleh di-commit ke repositori.
- Gunakan `.env.example` sebagai referensi konfigurasi lingkungan lokal.
- Token otentikasi disimpan menggunakan penyimpanan aman native perangkat (*secure storage*).
