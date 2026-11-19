# KasbonKu

**Bon tercatat, bayar tenang.**

KasbonKu adalah aplikasi Flutter untuk mencatat kasbon (utang) pribadi saat membeli makanan atau minuman di warung. Aplikasi ini menggantikan catatan di kertas atau mengandalkan ingatan: setiap item dan harga langsung tercatat, total dihitung otomatis, dan pembayaran sebagian maupun pelunasan tersimpan rapi.

## Masalah yang diselesaikan

- Bon tidak pernah tercatat, akhirnya lupa sudah berutang berapa.
- Item dicatat tanpa harga, sehingga total harus dihitung ulang saat membayar.
- Pembayaran sebagian tidak terdokumentasi.
- Menu baru tidak ikut tercatat.

## Fitur

- Catat bon baru: nama warung, item, qty, harga satuan, dan catatan.
- Menu cepat untuk item yang sering dibeli (Magelangan, Es Teh, Sate).
- Subtotal dan total dihitung otomatis.
- Pembayaran penuh atau sebagian, dengan sisa dan status yang diperbarui otomatis.
- Status bon: **Belum bayar**, **Dibayar sebagian**, dan **Lunas**.
- Riwayat bon aktif dan bon lunas.
- Data tersimpan lokal di browser/HP memakai `shared_preferences`.
- Tanpa login, tanpa backend, dan tanpa API key.

## Teknologi

- Flutter 3.50 / Dart 3.14
- Material 3
- `shared_preferences` untuk penyimpanan lokal
- Format rupiah kustom (tanpa dependensi tambahan)

## Menjalankan aplikasi

Prasyarat: Flutter SDK sudah terpasang dan Chrome tersedia.

```bash
flutter pub get
flutter run -d chrome
```

Membuat build web:

```bash
flutter build web --release
```

Menjalankan hasil build secara lokal:

```bash
node server.js
```

Lalu buka <http://localhost:8080>. Di Windows, `start_demo.bat` bisa dipakai untuk menjalankan server dan membuka browser sekaligus.

## Skenario demo

1. Buka aplikasi. Data awal kosong.
2. Tap **Bon baru**.
3. Tap menu **Magelangan**, lalu tombol **+** sampai qty 2.
4. Tap menu **Es Teh** sebanyak 1.
5. Total otomatis menjadi **Rp32.000**. Tap **Simpan Bon**.
6. Buka bon tersebut, lalu tap **Bayar Kasbon**.
7. Bayar **Rp20.000**. Status berubah menjadi **Dibayar sebagian** dengan sisa **Rp12.000**.
8. Bayar **Rp12.000** atau tap **Lunasi**. Status berubah menjadi **Lunas**.
9. Refresh halaman. Data tetap tersimpan.

## Struktur proyek

```text
lib/main.dart      # model, penyimpanan, dan seluruh UI aplikasi
web/               # entry point Flutter web
server.js          # server statis sederhana untuk build web
start_demo.bat     # pembuka demo di Windows
```

## Catatan

- Data disimpan di perangkat/browser yang dipakai, belum tersinkron antar perangkat.
- Harga pada menu cepat dapat diubah di `lib/main.dart`.
