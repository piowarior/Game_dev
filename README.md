
# SIAGA BENCANA: SAR RESCUE MISSION

**Implementasi Digital Game-Based Learning pada Simulator Bencana untuk Edukasi Strategi Mitigasi Bencana Alam di Indonesia**

---

## 📌 Konsep Game
**SIAGA BENCANA** adalah sebuah *serious game* bertipe simulasi penyelamatan (*rescue simulation*) dengan sudut pandang *top-down* 2D. Game ini dirancang menggunakan pendekatan **Digital Game-Based Learning (DGBL)** untuk memberikan pengalaman simulatif yang aman namun realistis dalam menghadapi situasi darurat di Indonesia.

[cite_start]Pemain berperan sebagai anggota tim penyelamat profesional (terinspirasi dari SAR dan relawan BNPB) yang ditugaskan untuk menangani berbagai skenario bencana. Tujuan utamanya adalah untuk melatih **pengambilan keputusan kritis**, pemahaman **Standard Operational Procedure (SOP)** resmi, dan penggunaan peralatan penyelamatan yang tepat.

---

## 🌍 Latar Belakang & Visi
Indonesia berada di wilayah *Ring of Fire*, yang menjadikannya sangat rentan terhadap bencana alam seperti gempa bumi, banjir, dan tanah longsor. Namun, tingkat literasi masyarakat mengenai mitigasi bencana masih tergolong rendah. 

**SIAGA BENCANA** hadir sebagai solusi inovatif dalam bentuk *serious game*. Visi proyek ini adalah menciptakan media pembelajaran yang interaktif dan imersif, di mana pengguna dapat belajar melalui simulasi langsung tanpa risiko fisik, sehingga siap menghadapi situasi darurat di dunia nyata.

---

## 🎯 Tujuan Pengembangan
*   **Meningkatkan Literasi Kebencanaan**: Memberikan pemahaman mendalam mengenai jenis-jenis bencana di Indonesia.
*   **Pelatihan Pengambilan Keputusan**: Melatih pemain untuk berpikir cepat dan tepat dalam kondisi kritis di bawah tekanan waktu.
*   **Implementasi SOP**: Mengedukasi pemain mengenai *Standard Operational Procedure* (SOP) penyelamatan yang benar sesuai standar tim SAR/BNPB.
*   **Pengenalan Alat**: Memperkenalkan berbagai fungsi alat penyelamatan (seperti APAR, Tandu, Pelampung, dll.).

---

## 🎮 Fitur Utama & Mekanik Permainan

### 1. Skenario Bencana Multi-Dimensi
Permainan mencakup berbagai skenario yang masing-masing membutuhkan strategi berbeda:
*   **Skenario Banjir**: Fokus pada evakuasi air, penggunaan pelampung, dan navigasi jalur air.
*   **Skenario Gempa**: Fokus pada pencarian korban di reruntuhan dan teknik evakuasi vertikal.
*   **Skenario Kebakaran**: Fokus pada penggunaan APAR dan manajemen paparan asap.
*   **Skenario Tanah Longsor**: Fokus pada pembersihan jalur dan evakuasi medan miring.

### 2. Sistem Triage (Manajemen Korban)
Sistem penilaian kondisi korban yang realistis untuk menentukan prioritas evakuasi:
*   🔴 **Kritis (Triage Merah)**: Membutuhkan pertolongan segera (P3K) dan evakuasi pertama.
*   🟡 **Sedang (Triage Kuning)**: Korban tidak bisa berjalan, memerlukan alat angkut seperti tandu.
*   🟢 **Ringan (Triage Hijau)**: Korban masih bisa dipandu menuju titik aman secara mandiri.

### 3. Sistem Inventori & Markas (Hub)
*   **Penyiapan Loadout**: Sebelum misi, pemain harus memilih alat yang sesuai di rak peralatan.
*   **Kapasitas Terbatas**: Pemain tidak bisa membawa semua alat, memaksa pemain untuk menganalisis kebutuhan misi berdasarkan *briefing*.

---

## 🏗️ Arsitektur Sistem & Kelas Data
Game ini dikembangkan dengan pendekatan modular berbasis sistem kelas untuk efisiensi performa:

*   **`PlayerClass`**: Mengelola data pemain, kesehatan (*health*), dan statistik performa.
*   **`PeralatanClass`**: Mengatur database alat, stok, dan fungsi interaksi alat terhadap objek.
*   **`KorbanClass`**: Mengatur atribut korban, posisi, tingkat keparahan, dan logika respons terhadap alat.
*   **`MisiClass`**: Mengatur aturan main (logika *win/lose*), batas waktu, dan objek bahaya (*Hazard*) di peta.

---

## 💻 Spesifikasi Teknis
*   **Game Engine**: Godot Engine 4.x (Optimasi performa tinggi dengan sistem node).
*   **Bahasa Pemrograman**: GDScript (Event-driven programming).
*   **Gaya Visual**: *Retro 16-bit Pixel Art* dengan resolusi tinggi (32x32 per icon) untuk estetika klasik yang bersih.
*   **Perspektif**: *Top-Down 2D* untuk memberikan pandangan luas terhadap medan bencana.
*   **Platform**: Desktop (Windows/PC).

---

## 🔄 Alur Permainan (User Journey)
1.  **Briefing Misi**: Pemain menerima informasi detail mengenai bencana dan tantangan yang akan dihadapi.
2.  **Pemilihan Alat (Loadout)**: Memilih peralatan yang tepat di markas berdasarkan hasil *briefing*.
3.  **Operasi Penyelamatan**: Pemain masuk ke peta, melakukan eksplorasi, menolong korban, dan menghindari bahaya sekeliling.
4.  **Titik Evakuasi**: Membawa korban kembali ke zona aman (Ambulans/Posko).
5.  **Evaluasi & Skor**: Mendapatkan bintang (1-3) berdasarkan kecepatan, ketepatan penanganan, dan jumlah korban yang selamat.

---

## 🧠 Metodologi Pembelajaran (DGBL)
Proyek ini mengintegrasikan empat pilar risiko bencana ke dalam *gameplay*:
*   **Hazard (Bahaya)**: Ancaman fisik dalam game (api, reruntuhan).
*   **Vulnerability (Kerentanan)**: Kondisi korban yang berbeda-beda.
*   **Capacity (Kapasitas)**: Pengetahuan dan peralatan yang dimiliki pemain.
*   **Exposure (Paparan)**: Luas area terdampak bencana yang harus dijelajahi.

---

## 👤 Tim Pengembang (Made By)
Proyek ini merupakan karya orisinal yang dikembangkan secara intensif oleh:

*   **Muhamad Rohisul Iman**
*   **Muhamad Virga Mulia**
*   **Angga Yunanda**
*   **Ivan Edward**
---
*Proyek ini diajukan untuk meningkatkan standar edukasi mitigasi bencana digital di lingkungan akademis dan masyarakat luas.*
