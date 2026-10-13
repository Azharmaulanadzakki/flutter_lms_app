const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();
const now = FieldValue.serverTimestamp();

// q(pertanyaan, [pilihan A..D], indeks jawaban benar (0..3), pembahasan)
const q = (text, options, correctIndex, explanation) => ({ text, options, correctIndex, explanation });

// durationMinutes: 0 = tanpa timer
const postTests = {
  'course-1': {
    title: 'Post-Test: Pengenalan Komponen Komputer',
    durationMinutes: 0,
    questions: [
      q('Komponen yang menyimpan data sementara yang sedang diproses CPU adalah ...',
        ['Harddisk', 'RAM', 'Power Supply', 'Casing'], 1,
        'RAM menyimpan data sementara yang sedang diproses CPU. Datanya hilang saat listrik mati.'),
      q('Perangkat yang termasuk perangkat output adalah ...',
        ['Mouse', 'Scanner', 'Webcam', 'Monitor'], 3,
        'Monitor menampilkan hasil pengolahan data. Mouse, scanner, dan webcam adalah perangkat input.'),
      q('Bagian komputer yang menyuplai arus listrik ke seluruh komponen adalah ...',
        ['Power Supply', 'Motherboard', 'VGA Card', 'Heatsink'], 0,
        'Power Supply (PSU) mengubah listrik AC menjadi DC dan membagikannya ke komponen.'),
      q('Kartu yang bertugas memproses dan menampilkan gambar ke monitor adalah ...',
        ['Sound card', 'Network card', 'VGA / kartu grafis', 'Capture card'], 2,
        'VGA atau kartu grafis (GPU) memproses data visual untuk ditampilkan di monitor.'),
      q('Fungsi utama casing komputer adalah ...',
        ['Mengolah data', 'Melindungi dan menampung komponen di dalamnya',
         'Menyimpan data permanen', 'Menaikkan tegangan listrik'], 1,
        'Casing melindungi komponen, menata posisinya, dan membantu sirkulasi udara.'),
    ],
  },
  'course-2': {
    title: 'Post-Test: Motherboard dan CPU',
    durationMinutes: 10,
    questions: [
      q('Slot pada motherboard yang umum dipakai untuk memasang kartu grafis adalah ...',
        ['Slot DIMM', 'Konektor SATA', 'Socket CPU', 'Slot PCIe x16'], 3,
        'Kartu grafis dipasang pada slot PCIe x16.'),
      q('Satuan kecepatan clock prosesor adalah ...',
        ['Watt', 'Hertz (GHz)', 'Byte', 'Volt'], 1,
        'Kecepatan clock prosesor dinyatakan dalam Hertz, umumnya GHz.'),
      q('Fungsi heatsink dan kipas pada prosesor adalah ...',
        ['Membuang panas dari prosesor', 'Menambah kapasitas RAM',
         'Menyimpan BIOS', 'Mengubah arus listrik'], 0,
        'Heatsink dan kipas memindahkan panas prosesor ke udara agar suhunya terjaga.'),
      q('Firmware yang menyimpan pengaturan dasar perangkat keras dan dijalankan saat komputer menyala adalah ...',
        ['Driver', 'Antivirus', 'BIOS/UEFI', 'Sistem file'], 2,
        'BIOS atau UEFI menginisialisasi perangkat keras sebelum sistem operasi dimuat.'),
      q('Sebelum memasang prosesor ke socket, hal yang harus diperhatikan adalah ...',
        ['Warna prosesor', 'Penanda segitiga pada prosesor sejajar dengan penanda pada socket',
         'Merek kipas casing', 'Panjang kabel power'], 1,
        'Penanda segitiga memastikan arah prosesor benar sehingga pin atau kontaknya tidak rusak.'),
    ],
  },
  'course-3': {
    title: 'Post-Test: RAM dan Storage',
    durationMinutes: 10,
    questions: [
      q('Dual channel pada RAM berarti ...',
        ['Dua modul RAM bekerja berpasangan untuk meningkatkan bandwidth',
         'Satu modul memiliki dua slot', 'RAM memakai dua kabel daya',
         'RAM berfungsi sebagai storage kedua'], 0,
        'Dua modul berpasangan membuka dua jalur data sehingga bandwidth memori naik.'),
      q('Storage yang tidak memiliki bagian bergerak adalah ...',
        ['HDD', 'Floppy disk', 'SSD', 'Optical drive'], 2,
        'SSD memakai memori flash tanpa piringan atau kepala baca yang bergerak.'),
      q('Antarmuka storage yang menggunakan kabel data dan kabel daya terpisah adalah ...',
        ['M.2 NVMe', 'SATA', 'USB-C', 'PCIe x16'], 1,
        'SATA memakai satu kabel data dan satu kabel daya (SATA power).'),
      q('RAM yang dipasang pada laptop umumnya berbentuk ...',
        ['DIMM', 'Cache L3', 'VRAM', 'SO-DIMM'], 3,
        'SO-DIMM adalah modul RAM berukuran lebih kecil untuk laptop.'),
      q('Setelah memasang SSD baru yang kosong, langkah sebelum dipakai menyimpan data adalah ...',
        ['Inisialisasi dan membuat partisi/format', 'Mengganti thermal paste',
         'Mengganti kipas casing', 'Mengganti baterai CMOS'], 0,
        'Storage baru perlu diinisialisasi, dipartisi, dan diformat agar dikenali sistem operasi.'),
    ],
  },
  'course-4': {
    title: 'Post-Test: Power Supply dan Kabel',
    durationMinutes: 10,
    questions: [
      q('Sertifikasi 80 PLUS pada power supply menunjukkan ...',
        ['Jumlah kipas', 'Efisiensi konversi daya', 'Warna kabel', 'Kapasitas RAM'], 1,
        '80 PLUS menandakan PSU mengubah daya dengan efisiensi minimal 80%.'),
      q('Konektor PCIe 6+2 pin pada PSU digunakan untuk ...',
        ['Harddisk', 'Motherboard', 'Prosesor', 'Kartu grafis'], 3,
        'Konektor PCIe menyuplai daya tambahan ke kartu grafis.'),
      q('Jika daya PSU terlalu kecil untuk sistem, akibat yang mungkin terjadi adalah ...',
        ['PC mati atau restart sendiri saat beban berat', 'Kapasitas RAM bertambah',
         'Layar menjadi lebih terang', 'Prosesor menjadi lebih cepat'], 0,
        'Daya yang kurang membuat sistem tidak stabil, terutama saat beban berat.'),
      q('Konektor molex 4-pin berukuran besar pada PSU lama dipakai antara lain untuk ...',
        ['Kartu grafis modern', 'Kabel LAN', 'Kipas atau perangkat lama', 'Monitor'], 2,
        'Molex menyuplai daya ke kipas dan perangkat lama seperti drive IDE.'),
      q('Hal yang perlu dihindari saat merapikan kabel adalah ...',
        ['Mengikat kabel dengan cable tie secukupnya',
         'Menekuk kabel terlalu tajam atau menarik konektor dengan paksa',
         'Menyusun kabel di balik tray motherboard', 'Menjauhkan kabel dari kipas'], 1,
        'Kabel yang ditekuk tajam atau ditarik paksa dapat rusak dan konektornya longgar.'),
    ],
  },
  'course-5': {
    title: 'Post-Test: Perakitan PC',
    durationMinutes: 10,
    questions: [
      q('Lapisan thermal paste yang ideal adalah ...',
        ['Setebal mungkin', 'Tidak perlu sama sekali',
         'Tipis dan merata (seukuran biji jagung)', 'Dioleskan pada seluruh motherboard'], 2,
        'Lapisan tipis sudah cukup mengisi celah mikro. Terlalu tebal justru menghambat perpindahan panas.'),
      q('Posisi pemasangan 2 modul RAM pada motherboard dengan 4 slot mengikuti ...',
        ['Slot terjauh dari CPU saja', 'Slot mana saja tanpa aturan',
         'Slot yang paling dekat PSU',
         'Petunjuk di manual motherboard (umumnya slot A2 dan B2)'], 3,
        'Manual motherboard menunjukkan slot yang benar agar dual channel aktif.'),
      q('Sumber petunjuk terbaik untuk memasang kabel panel depan casing (power SW, reset SW, LED) adalah ...',
        ['Manual motherboard', 'Manual monitor', 'Manual keyboard', 'Kemasan RAM'], 0,
        'Letak pin front panel berbeda-beda; manual motherboard memuat diagramnya.'),
      q('Jika PC menyala tetapi tidak ada tampilan setelah dirakit, langkah pertama yang dilakukan adalah ...',
        ['Mengganti PSU baru', 'Memeriksa ulang pemasangan RAM dan kabel monitor',
         'Menginstal ulang sistem operasi', 'Membeli motherboard baru'], 1,
        'Penyebab paling umum adalah RAM kurang tertancap atau kabel monitor salah port.'),
      q('Setelah PC berhasil menyala dan lolos POST, langkah berikutnya adalah ...',
        ['Membongkar kembali semua komponen', 'Mengganti casing',
         'Menginstal sistem operasi dan driver', 'Menyolder ulang motherboard'], 2,
        'PC yang lolos POST siap diinstal sistem operasi dan driver.'),
    ],
  },
  'course-6': {
    title: 'Post-Test: Troubleshooting PC',
    durationMinutes: 10,
    questions: [
      q('PC menyala tetapi monitor menampilkan "No Signal". Penyebab yang paling mudah diperiksa pertama adalah ...',
        ['Kabel video belum terpasang kencang atau salah input monitor',
         'Sistem operasi rusak', 'Prosesor terbakar', 'Hard disk penuh'], 0,
        'Mulai dari yang paling sederhana: kabel video dan pilihan input pada monitor.'),
      q('Suara klik berulang dari harddisk yang sedang dipakai biasanya menandakan ...',
        ['RAM kurang', 'Kipas berdebu', 'Kemungkinan kerusakan fisik pada harddisk', 'Monitor rusak'], 2,
        'Bunyi klik berulang sering menandakan kerusakan mekanis; segera cadangkan data.'),
      q('Langkah untuk memastikan RAM bermasalah atau tidak adalah ...',
        ['Mengganti wallpaper', 'Mencoba satu modul bergantian di slot berbeda',
         'Menurunkan resolusi', 'Mengganti mouse'], 1,
        'Menguji modul satu per satu di slot berbeda menunjukkan modul atau slot yang bermasalah.'),
      q('Blue screen (BSOD) yang sering muncul dapat disebabkan oleh ...',
        ['Warna casing', 'Ukuran monitor', 'Panjang kabel LAN',
         'Driver bermasalah atau perangkat keras tidak stabil'], 3,
        'BSOD biasanya dipicu driver yang bermasalah atau perangkat keras yang tidak stabil.'),
      q('Dokumentasi yang baik dalam troubleshooting adalah ...',
        ['Mencatat gejala, langkah yang dicoba, dan hasilnya', 'Hanya mengandalkan ingatan',
         'Menghapus semua catatan sebelumnya', 'Tidak perlu dicatat'], 0,
        'Catatan membantu melacak penyebab dan menghindari langkah yang diulang.'),
    ],
  },
};

async function main() {
  const batch = db.batch();
  let questionTotal = 0;

  for (const [courseId, test] of Object.entries(postTests)) {
    const testId = `${courseId}-post`;

    batch.set(db.collection('tests').doc(testId), {
      courseId,
      type: 'post',
      title: test.title,
      questionCount: test.questions.length,
      durationMinutes: test.durationMinutes,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    });

    test.questions.forEach((item, i) => {
      const questionId = `${testId}-q${i + 1}`;

      batch.set(db.collection('questions').doc(questionId), {
        testId,
        courseId,
        question: item.text,
        options: item.options,
        points: 1,
        order: i + 1,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      });

      batch.set(db.collection('questionKeys').doc(questionId), {
        testId,
        courseId,
        correctIndex: item.correctIndex,
        explanation: item.explanation,
        updatedAt: now,
      });

      questionTotal++;
    });
  }

  await batch.commit();
  console.log(`Selesai: ${Object.keys(postTests).length} post-test, ${questionTotal} soal.`);
}

main().catch((e) => { console.error(e); process.exit(1); });