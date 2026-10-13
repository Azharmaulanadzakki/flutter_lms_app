const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const serviceAccount = require("./serviceAccountKey.json");

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();
const now = FieldValue.serverTimestamp();

// ---------- COURSE ----------
const courses = [
  {
    id: "course-1",
    title: "Pengenalan Komponen Komputer",
    level: "Dasar",
    duration: 45,
    description: "Mengenal komponen utama komputer dan fungsinya.",
  },
  {
    id: "course-2",
    title: "Motherboard dan CPU",
    level: "Dasar",
    duration: 60,
    description: "Memahami motherboard, socket, chipset, dan prosesor.",
  },
  {
    id: "course-3",
    title: "RAM dan Storage",
    level: "Menengah",
    duration: 60,
    description: "Jenis RAM, HDD, SSD, dan cara memasangnya.",
  },
  {
    id: "course-4",
    title: "Power Supply dan Kabel",
    level: "Menengah",
    duration: 45,
    description: "Fungsi PSU, konektor daya, dan manajemen kabel.",
  },
  {
    id: "course-5",
    title: "Perakitan PC",
    level: "Menengah",
    duration: 90,
    description: "Langkah perakitan PC dari awal sampai menyala.",
  },
  {
    id: "course-6",
    title: "Troubleshooting PC",
    level: "Lanjut",
    duration: 75,
    description: "Mendiagnosis dan memperbaiki masalah umum pada PC.",
  },
];

// ---------- MATERI ----------
// text  : isi di `content`
// video : isi `mediaUrl` dengan link YouTube, lalu publish
// pdf   : isi `mediaUrl` dengan link PDF, lalu publish
const text = (title, content) => ({
  type: "text",
  title,
  content,
  mediaUrl: "",
  isPublished: true,
});
const video = (title) => ({
  type: "video",
  title,
  content: "",
  mediaUrl: "",
  isPublished: false,
});
const pdf = (title) => ({
  type: "pdf",
  title,
  content: "",
  mediaUrl: "",
  isPublished: false,
});

const materials = {
  "course-1": [
    text(
      "Apa itu Komputer?",
      "Komputer adalah perangkat elektronik yang menerima data (input), memprosesnya, lalu menghasilkan informasi (output). Komponen utamanya terdiri dari perangkat input, proses, penyimpanan, dan output.",
    ),
    text(
      "Komponen Utama di Dalam Casing",
      "Komponen utama: motherboard, CPU, RAM, storage (HDD/SSD), power supply, dan kartu grafis. Semuanya terpasang di dalam casing dan saling terhubung lewat motherboard.",
    ),
    video("Video: Pengenalan Komponen PC"),
    pdf("Modul PDF: Pengenalan Komponen"),
  ],
  "course-2": [
    text(
      "Apa itu Motherboard?",
      "Motherboard adalah papan utama yang menghubungkan semua komponen komputer. Bagian pentingnya: socket CPU, slot RAM, slot PCIe, konektor SATA/M.2, dan chipset.",
    ),
    text(
      "Fungsi dan Socket CPU",
      "CPU adalah otak komputer yang menjalankan instruksi. CPU harus cocok dengan socket motherboard, misalnya LGA1700 untuk Intel atau AM5 untuk AMD.",
    ),
    video("Video: Cara Memasang CPU"),
    pdf("Modul PDF: Motherboard dan CPU"),
  ],
  "course-3": [
    text(
      "Fungsi RAM",
      "RAM menyimpan data sementara yang sedang diproses CPU. Datanya hilang saat komputer dimatikan. Jenis umum saat ini: DDR4 dan DDR5, yang tidak saling kompatibel.",
    ),
    text(
      "HDD vs SSD",
      "HDD memakai piringan magnetik: murah, kapasitas besar, lebih lambat. SSD memakai memori flash: jauh lebih cepat, lebih tahan guncangan, harga per GB lebih tinggi.",
    ),
    text(
      "Cara Memasang RAM",
      "Buka klip slot RAM, cocokkan takik pada modul dengan slot, lalu tekan hingga klip menutup dengan bunyi klik. Kesalahan umum: memasang terbalik atau kurang dalam.",
    ),
    video("Video: Memasang RAM dan SSD"),
  ],
  "course-4": [
    text(
      "Fungsi Power Supply (PSU)",
      "PSU mengubah arus listrik AC dari stopkontak menjadi arus DC yang dibutuhkan komponen. Pilih daya (watt) yang sesuai kebutuhan sistem, dengan cadangan secukupnya.",
    ),
    text(
      "Konektor Daya Utama",
      "Konektor utama: 24-pin ke motherboard, 4/8-pin CPU, PCIe untuk kartu grafis, dan SATA untuk storage. Pastikan setiap konektor terpasang penuh.",
    ),
    video("Video: Manajemen Kabel"),
  ],
  "course-5": [
    text(
      "Persiapan Perakitan",
      "Siapkan obeng, thermal paste, dan gelang antistatik atau sentuh logam casing untuk membuang listrik statis. Kerjakan di permukaan yang bersih dan rata.",
    ),
    text(
      "Urutan Perakitan",
      "Urutan umum: pasang CPU, pasang pendingin, pasang RAM, pasang motherboard ke casing, pasang storage, pasang PSU, sambungkan kabel, lalu uji nyala.",
    ),
    text(
      "Kesalahan Umum",
      "Lupa memasang standoff, CPU terpasang miring, RAM kurang dalam, kabel power CPU belum tersambung, dan lupa melepas plastik pelindung pendingin.",
    ),
    video("Video: Perakitan PC Lengkap"),
    pdf("Modul PDF: Langkah Perakitan PC"),
  ],
  "course-6": [
    text(
      "Prinsip Dasar Troubleshooting",
      "Mulai dari yang paling sederhana: kabel dan konektor, lalu daya, lalu komponen. Ubah satu hal pada satu waktu dan catat hasilnya.",
    ),
    text(
      "PC Tidak Menyala",
      "Cek stopkontak dan saklar PSU, konektor 24-pin dan CPU power, lalu tombol power pada casing. Jika kipas berputar tetapi tidak ada tampilan, cek RAM dan kartu grafis.",
    ),
    text(
      "Beep Code dan Layar Kosong",
      "Bunyi beep dari motherboard menandakan jenis masalah, misalnya RAM atau VGA. Lihat manual motherboard untuk arti polanya.",
    ),
    video("Video: Studi Kasus Troubleshooting"),
  ],
};

async function main() {
  const batch = db.batch();

  courses.forEach((c, i) => {
    batch.set(db.collection("courses").doc(c.id), {
      title: c.title,
      description: c.description,
      thumbnailUrl: "",
      level: c.level,
      duration: c.duration,
      order: i + 1,
      isPublished: true,
      createdAt: now,
      updatedAt: now,
    });
  });

  let count = 0;
  for (const [courseId, list] of Object.entries(materials)) {
    list.forEach((m, i) => {
      batch.set(db.collection("materials").doc(`${courseId}-m${i + 1}`), {
        courseId,
        title: m.title,
        content: m.content,
        type: m.type,
        mediaUrl: m.mediaUrl,
        order: i + 1,
        isPublished: m.isPublished,
        createdAt: now,
        updatedAt: now,
      });
      count++;
    });
  }

  await batch.commit();
  console.log(`Selesai: ${courses.length} course, ${count} materi.`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
