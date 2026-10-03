# Realita +62: Papan Kehidupan

> English: [README.md](./README.md) | Bahasa Indonesia: berkas ini

[![Status CI](https://github.com/tukiza7-debug/realita-62-life-board/actions/workflows/build-flutter-apk.yml/badge.svg?branch=main)](https://github.com/tukiza7-debug/realita-62-life-board/actions/workflows/build-flutter-apk.yml)
[![Rilis terbaru](https://img.shields.io/github/v/release/tukiza7-debug/realita-62-life-board)](https://github.com/tukiza7-debug/realita-62-life-board/releases/latest)
[![Lisensi: MIT](https://img.shields.io/badge/Lisensi-MIT-yellow.svg)](./LICENSE)
[![Flutter 3.24.0](https://img.shields.io/badge/Flutter-3.24.0-02569B?logo=flutter)](https://flutter.dev/)
[![Android 7.0+](https://img.shields.io/badge/Android-7.0%2B-green?logo=android)](https://developer.android.com/about/versions/nougat)

Permainan papan bergaya Game of Life yang memadukan mekanik klasik dengan realitas sosio-ekonomi dan politik Indonesia modern. Bertahanlah menghadapi inflasi, kebijakan pemerintah, dan godaan korupsi — capai pensiun dengan bermartabat.

## Ringkasan singkat

- **Genre**: permainan papan keluarga berbasis giliran, main bergiliran pada satu perangkat, atau sendiri melawan AI (1–3 lawan AI).
- **Pemain**: 2–4 lokal.
- **Bahasa**: English + Bahasa Indonesia (bisa diganti langsung, tanpa mulai ulang).
- **Luring**: 100% luring. Tanpa akun, tanpa iklan, tanpa analitik, tanpa izin INTERNET (diverifikasi di `AndroidManifest.xml`).
- **Engine**: RNG deterministik dengan seed — seed yang sama menghasilkan permainan yang identik dengan aplikasi Kotlin lama dan port Flutter ini.

## Unduh dan pasang

Ambil APK terbaru dari [halaman Rilis](https://github.com/tukiza7-debug/realita-62-life-board/releases/latest).

- Untuk ponsel modern: `app-arm64-v8a-release.apk`.
- Jika ragu atau memasang di emulator x86: `app-release.apk` (APK universal).
- Memerlukan Android 7.0 (API 24) atau lebih baru.

Izinkan pemasangan dari browser/aplikasi berkas Anda jika Android memblokirnya. Jika muncul "Aplikasi tidak terpasang", penyebab paling mungkin adalah ketidakcocokan tanda tangan — copot pemasangan build sebelumnya terlebih dahulu.

Verifikasi unduhan dengan `SHA256SUMS.txt`:

```bash
sha256sum -c SHA256SUMS.txt   # di direktori yang berisi file .apk
```

## Cara bermain (ringkas)

1. Pilih jalur pendidikan: **PTN (Kuliah)** bermula dengan Rp 2M tunai dan utang UKT Rp 10M; **SMA/SMK** bermula dengan Rp 3M tanpa utang.
2. Lempar dadu. Main bergiliran antara 2–4 pemain, atau sendiri melawan AI.
3. **Payday** (setiap 5 tile) memberi gaji sesuai pekerjaan. PNS dan SCBD dipotong 3% TAPERA.
4. **Event** menarik kartu *Nasib Warga +62* (kenaikan BBM, PHK massal, OTT KPK, kejutan PPN…).
5. **Luck** menarik Good Luck atau Bad Luck secara acak. Kerugian tunai dikurangi 25% bila tabungan ≥ Rp 10M; asuransi memangkas separuh tagihan medis.
6. Beli aset (Rumah Kampung Rp 20M, Apartemen Rp 35M, Tanah Jogja/Bali Rp 40M, Rumah Menteng Rp 120M) — ditambah PPN 12%, uang muka 20%, 80% KPR.
7. **Marriage**: Sederhana KUA (Rp 1M, +8 Kebahagiaan) atau Mewah (Rp 8M, +25 Kebahagiaan; selisihnya menjadi utang Pinjol jika tunai minus).
8. **Child**: setiap anak menambah Rp 1,5M per putaran. Biayai sekolahnya untuk bonus Dynasty.
9. **Mahar Partai** (Rp 15M): masuk jalur politik. Bersih (+Kebahagiaan, dicemo warga) atau Korupsi (curi Rp 6M per putaran, risiko OTT KPK = heat × 10%).
10. **Pensiun**: Jogja, Bali, atau Menteng. Skor = Aset Bersih + Tunai + (Kebahagiaan × Rp 0,5M) + Bonus Dynasty. Jalur Korupsi dengan Kebahagiaan negatif, skor dipotong separuh.
11. **Warga Teladan +62**: tanpa korupsi, tanpa Pinjol di akhir, Kebahagiaan positif, pensiun di Jogja atau Bali.

Aturan lengkap di [`docs/SPEC.md`](./docs/SPEC.md). Layar Tutorial dan Rules Reference dalam aplikasi memuat aturan yang sama.

## Build dari sumber

Persyaratan: Flutter 3.24.0 (stable), JDK 17, Android SDK platform `android-34` dan build-tools.

```bash
flutter pub get
flutter gen-l10n                # hasilkan file lokalisasi
flutter analyze                 # wajib nol masalah
flutter test                    # semua tes harus lulus
flutter run                     # build debug pada perangkat/emulator tersambung
flutter build apk --release --split-per-abi   # APK rilis per ABI
flutter build apk --release                   # APK universal
```

## Penandatanganan dan rilis (untuk pengelola)

Hasilkan keystore rilis (sekali saja):

```bash
keytool -genkeypair -v -keystore realita.keystore \
    -alias realita -keyalg RSA -keysize 2048 -validity 10000
```

Atur empat secret repositori di **Settings → Secrets and variables → Actions**:

- `REALITA_KEYSTORE_BASE64` — `base64 -w0 realita.keystore` (seluruh keystore, dienkode base64).
- `REALITA_KEYSTORE_PASSWORD` — kata sandi keystore.
- `REALITA_KEY_ALIAS` — `realita`.
- `REALITA_KEY_PASSWORD` — kata sandi kunci.

Rilis:

```bash
git tag v2.0.0
git push origin v2.0.0
```

Workflow di `.github/workflows/build-flutter-apk.yml` kemudian:
1. Menjalankan `flutter analyze` + `flutter test` + `dart format --set-exit-if-changed`.
2. Menjalankan `flutter build apk --release --split-per-abi` dan APK universal.
3. Menghitung `SHA256SUMS.txt`.
4. Membuat GitHub Release dengan APK dan `SHA256SUMS.txt` terlampir, isi badan dari bagian `CHANGELOG.md` yang sesuai.

Tanpa empat secret penandatanganan, build rilis akan jatuh ke penandatanganan debug sehingga APK tetap dapat dipasang untuk pengujian lokal; **rilis publik HARUS gagal jelas bila secret hilang** (master prompt bagian 11). Jangan pernah commit keystore atau kata sandi.

## Pengujian

```bash
flutter test                   # tes unit (engine, kartu, paritas RNG, simpan/muat)
flutter test integration_test  # tes integrasi (menu → setup → permainan → hasil)
```

Jalankan fuzz/simulasi dengan seed dan jumlah permainan tertentu:

```bash
dart test --plain-name "1000 simulated games finish cleanly"
```

## Privasi

Sepenuhnya luring. Tanpa akun, tanpa iklan, tanpa analitik, tanpa izin jaringan. Diverifikasi dengan memeriksa `android/app/src/main/AndroidManifest.xml` — manifest hanya mendeklarasikan `VIBRATE` (untuk getaran haptik) dan query untuk `ACTION_PROCESS_TEXT`. Tidak ada `<uses-permission android:name="android.permission.INTERNET"/>` di mana pun.

## FAQ / Pemecahan masalah

- **Pemasangan diblokir**: Android menampilkan "Untuk keamanan, ponsel Anda tidak diizinkan memasang aplikasi tidak dikenal dari sumber ini". Buka Pengaturan → Aplikasi → Akses khusus → Pasang aplikasi tidak dikenal → pilih browser/aplikasi berkas Anda → Izinkan.
- **Aplikasi tidak terpasang**: ketidakcocokan tanda tangan dengan build sebelumnya. Copot build lama terlebih dahulu.
- **Peringatan Play Protect**: ketuk "Detail lainnya" → "Tetap pasang". Realita +62 sepenuhnya luring dan tidak mengandung malware.
- **Save rusak**: permainan otomatis kembali ke layar Permainan Baru. Gunakan Pengaturan → Data → Hapus permainan tersimpan bila perlu.
- **Laporkan bug**: buka [isu GitHub](https://github.com/tukiza7-debug/realita-62-life-board/issues/new/choose) menggunakan templat Bug Report; sertakan versi aplikasi, versi Android, perangkat, bahasa, orientasi, dan seed permainan (terlihat di Pengaturan → Tentang → Salin info debug).

## Lisensi

MIT. Lihat [`LICENSE`](./LICENSE).

## Ucapan terima kasih

Dibuat dengan Flutter, Dart, Material 3, dan banyak realitas sehari-hari Indonesia. Master prompt dan rasional desain lengkap ada di `docs/`. Implementasi Kotlin lama berada di `legacy-kotlin/` sebagai referensi perilaku; engine Dart diverifikasi menghasilkan hasil yang identik untuk seed yang sama (lihat `test/engine_test.dart`).
