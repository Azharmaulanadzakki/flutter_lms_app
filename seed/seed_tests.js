const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();
const now = FieldValue.serverTimestamp();

// q(pertanyaan, [pilihan A..D], indeks jawaban benar (0..3), pembahasan)
const q = (text, options, correctIndex, explanation) => ({ text, options, correctIndex, explanation });

// durationMinutes: 0 = tanpa timer
const preTests = {
  'course-1': {
    title: 'Pre-Test: Pengenalan Komponen Komputer',
    durationMinutes: 0,
    questions: [
      q('Komponen yang berfungsi sebagai "otak" komputer dan mengeksekusi instruksi adalah ...',
        ['RAM', 'CPU', 'Power Supply', 'Harddisk'], 1,
        'CPU (Central Processing Unit) menjalankan instruksi dan mengolah data.'),
      q('Papan utama yang menghubungkan semua komponen komputer disebut ...',
        ['Motherboard', 'Casing', 'Heatsink', 'Soundcard'], 0,
        'Motherboard adalah papan sirkuit utama tempat semua komponen terhubung.'),
      q('Perangkat berikut yang termasuk perangkat input adalah ...',
        ['Monitor', 'Printer', 'Keyboard', 'Speaker'], 2,
        'Keyboard memasukkan data ke komputer. Monitor, printer, dan speaker adalah perangkat output.'),
      q('Komponen yang mengubah arus listrik AC menjadi DC untuk komponen komputer adalah ...',
        ['Motherboard', 'RAM', 'VGA Card', 'Power Supply'], 3,
        'Power Supply (PSU) mengubah listrik AC dari stopkontak menjadi DC.'),
      q('Penyimpanan yang datanya tetap ada saat komputer dimatikan adalah ...',
        ['RAM', 'Cache', 'Storage (HDD/SSD)', 'Register'], 2,
        'HDD dan SSD menyimpan data permanen, sedangkan RAM bersifat sementara.'),
    ],
  },
  'course-2': {
    title: 'Pre-Test: Motherboard dan CPU',
    durationMinutes: 10,
    questions: [
      q('Tempat memasang prosesor pada motherboard disebut ...',
        ['Slot PCIe', 'Socket CPU', 'Slot RAM', 'Konektor SATA'], 1,
        'Prosesor dipasang pada socket CPU.'),
      q('Socket LGA1700 dipakai oleh prosesor ...',
        ['Intel Core', 'AMD Ryzen', 'NVIDIA GeForce', 'Qualcomm Snapdragon'], 0,
        'LGA1700 adalah socket Intel Core generasi ke-12 sampai ke-14.'),
      q('Socket AM5 digunakan oleh prosesor ...',
        ['Intel Core', 'NVIDIA GeForce', 'AMD Ryzen', 'Qualcomm Snapdragon'], 2,
        'AM5 adalah socket AMD Ryzen generasi terbaru.'),
      q('Fungsi chipset pada motherboard adalah ...',
        ['Menyimpan data permanen', 'Mendinginkan prosesor', 'Mengubah arus listrik',
         'Mengatur komunikasi antara CPU dan komponen lain'], 3,
        'Chipset mengatur lalu lintas data antara CPU, RAM, storage, dan perangkat lain.'),
      q('Bahan yang dioleskan tipis di antara prosesor dan heatsink agar panas berpindah dengan baik adalah ...',
        ['Lem epoksi', 'Cairan pendingin', 'Thermal paste', 'Cat konduktif'], 2,
        'Thermal paste mengisi celah mikro sehingga perpindahan panas lebih baik.'),
    ],
  },
  'course-3': {
    title: 'Pre-Test: RAM dan Storage',
    durationMinutes: 10,
    questions: [
      q('RAM bersifat volatile, artinya ...',
        ['Data tetap ada saat listrik mati', 'Data hilang saat listrik mati',
         'Hanya bisa dibaca', 'Tidak bisa diganti'], 1,
        'Volatile berarti data hilang ketika daya dimatikan.'),
      q('Mengenai DDR4 dan DDR5, pernyataan yang benar adalah ...',
        ['Tidak kompatibel; slot dan takiknya berbeda', 'Bisa dipasang bergantian di slot yang sama',
         'Memiliki jumlah pin yang sama', 'Hanya dipakai pada laptop'], 0,
        'DDR4 dan DDR5 memiliki posisi takik berbeda sehingga tidak bisa saling dipasang.'),
      q('Kelebihan SSD dibanding HDD adalah ...',
        ['Kapasitas selalu lebih besar', 'Harga per GB lebih murah',
         'Kecepatan baca-tulis lebih tinggi', 'Memakai piringan magnetik'], 2,
        'SSD memakai memori flash sehingga jauh lebih cepat dan tahan guncangan.'),
      q('Saat memasang RAM, agar tidak terbalik yang harus dicocokkan adalah ...',
        ['Warna modul', 'Merek modul', 'Stiker pada modul', 'Takik (notch) modul dengan slot'], 3,
        'Takik pada modul harus sejajar dengan penyekat pada slot.'),
      q('SSD M.2 NVMe dipasang langsung pada ...',
        ['Casing', 'Motherboard', 'Power supply', 'Kipas casing'], 1,
        'Slot M.2 berada di motherboard.'),
    ],
  },
  'course-4': {
    title: 'Pre-Test: Power Supply dan Kabel',
    durationMinutes: 10,
    questions: [
      q('Konektor daya utama motherboard ATX umumnya berjenis ...',
        ['4-pin', '24-pin', '6-pin SATA', '3-pin'], 1,
        'Konektor ATX utama berukuran 24-pin (20+4).'),
      q('Konektor 4/8-pin pada PSU digunakan untuk memberi daya ke ...',
        ['Harddisk', 'Kipas casing', 'Monitor', 'Prosesor (CPU)'], 3,
        'Konektor EPS 4/8-pin menyuplai daya khusus untuk CPU.'),
      q('Satuan yang umum dipakai untuk menyatakan kapasitas daya PSU adalah ...',
        ['Volt', 'Ampere', 'Watt', 'Ohm'], 2,
        'Kapasitas PSU dinyatakan dalam watt.'),
      q('Konektor SATA power pada PSU dipakai untuk ...',
        ['Storage SATA seperti HDD dan SSD 2,5 inci', 'Prosesor', 'Motherboard', 'Kartu grafis kelas atas'], 0,
        'SATA power menyuplai daya untuk perangkat penyimpanan SATA.'),
      q('Tujuan cable management yang rapi adalah ...',
        ['Menambah daya PSU', 'Memperlancar aliran udara dan memudahkan perawatan',
         'Mempercepat prosesor', 'Menambah kapasitas RAM'], 1,
        'Kabel rapi tidak menghalangi udara dan memudahkan pemeriksaan.'),
    ],
  },
  'course-5': {
    title: 'Pre-Test: Perakitan PC',
    durationMinutes: 10,
    questions: [
      q('Cara mencegah kerusakan akibat listrik statis sebelum merakit PC adalah ...',
        ['Merakit di atas karpet', 'Memakai sarung tangan wol',
         'Memakai gelang antistatik atau menyentuh logam casing', 'Menyalakan kipas angin'], 2,
        'Gelang antistatik atau menyentuh logam casing membuang muatan statis dari tubuh.'),
      q('Urutan yang benar pada perakitan di atas motherboard adalah ...',
        ['Pendingin dulu, baru CPU', 'CPU dulu, baru pendingin',
         'Kabel dulu, baru motherboard', 'Thermal paste setelah pendingin terpasang'], 1,
        'CPU harus terpasang lebih dulu sebelum pendingin dipasang di atasnya.'),
      q('Standoff pada casing berfungsi untuk ...',
        ['Menahan motherboard agar tidak menyentuh casing logam secara langsung',
         'Mendinginkan RAM', 'Menyimpan data', 'Menyalurkan listrik ke monitor'], 0,
        'Standoff memberi jarak sehingga tidak terjadi korsleting dengan casing.'),
      q('Setelah semua komponen terpasang, langkah pengujian pertama adalah ...',
        ['Menginstal semua aplikasi', 'Mengganti thermal paste', 'Memformat storage',
         'Menyalakan PC dan memeriksa apakah tampilan muncul (POST)'], 3,
        'Pengujian awal adalah memastikan PC menyala dan lolos POST.'),
      q('Penyebab umum PC tidak menyala setelah dirakit adalah ...',
        ['Warna casing tidak cocok', 'Kabel power CPU 4/8-pin belum tersambung',
         'Mouse terlalu lama', 'Keyboard tanpa lampu'], 1,
        'CPU tidak mendapat daya jika kabel 4/8-pin belum terpasang.'),
    ],
  },
  'course-6': {
    title: 'Pre-Test: Troubleshooting PC',
    durationMinutes: 10,
    questions: [
      q('Langkah paling sederhana saat PC tidak menyala adalah ...',
        ['Mengganti motherboard', 'Menginstal ulang OS', 'Memeriksa kabel power dan stopkontak', 'Mengganti RAM'], 2,
        'Mulai dari hal paling sederhana: kabel dan sumber listrik.'),
      q('Kipas berputar tetapi layar kosong. Komponen yang pertama dicek adalah ...',
        ['Keyboard', 'RAM dan kartu grafis', 'Speaker', 'Mouse'], 1,
        'Layar kosong dengan kipas berputar sering disebabkan RAM atau VGA kurang tertancap.'),
      q('Bunyi beep saat PC dinyalakan (POST) menandakan ...',
        ['Kerusakan layar saja', 'Koneksi internet terputus', 'Pembaruan sistem operasi',
         'Kode kesalahan perangkat keras (lihat manual motherboard)'], 3,
        'Pola beep adalah kode diagnosis dari BIOS; artinya ada di manual motherboard.'),
      q('Prinsip yang baik dalam troubleshooting adalah ...',
        ['Mengubah satu hal pada satu waktu dan mencatat hasilnya', 'Mengganti banyak komponen sekaligus',
         'Langsung membongkar semuanya', 'Mengabaikan gejala awal'], 0,
        'Mengubah satu hal setiap kali membuat penyebab masalah mudah dilacak.'),
      q('PC sering mati sendiri saat dipakai berat. Penyebab yang perlu dicek adalah ...',
        ['Warna wallpaper', 'Ukuran font', 'Suhu prosesor terlalu tinggi (pendingin atau thermal paste)', 'Volume speaker'], 2,
        'Suhu berlebih memicu proteksi panas sehingga PC mati sendiri.'),
    ],
  },
};

async function main() {
  const batch = db.batch();
  let questionTotal = 0;

  for (const [courseId, test] of Object.entries(preTests)) {
    const testId = `${courseId}-pre`;

    batch.set(db.collection('tests').doc(testId), {
      courseId,
      type: 'pre',
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
  console.log(`Selesai: ${Object.keys(preTests).length} pre-test, ${questionTotal} soal.`);
}

main().catch((e) => { console.error(e); process.exit(1); });