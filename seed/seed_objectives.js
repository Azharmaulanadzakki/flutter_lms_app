const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

// hasGame: true jika course punya simulasi 3D (bisa diubah kapan saja di Console).
const extra = {
  'course-1': { hasGame: false, objectives: [
    'Menyebutkan komponen utama komputer',
    'Menjelaskan fungsi tiap komponen',
    'Membedakan perangkat input, proses, dan output',
  ] },
  'course-2': { hasGame: false, objectives: [
    'Mengidentifikasi bagian-bagian motherboard',
    'Menjelaskan fungsi CPU dan socket',
    'Mencocokkan CPU dengan motherboard',
  ] },
  'course-3': { hasGame: false, objectives: [
    'Membedakan jenis RAM (DDR4 dan DDR5)',
    'Membandingkan HDD dan SSD',
    'Memasang RAM dan storage dengan benar',
  ] },
  'course-4': { hasGame: false, objectives: [
    'Menjelaskan fungsi power supply',
    'Mengenali konektor daya utama',
    'Menata kabel dengan rapi',
  ] },
  'course-5': { hasGame: true, objectives: [
    'Menyiapkan alat dan lingkungan kerja perakitan',
    'Merakit PC sesuai urutan yang benar',
    'Menguji PC sampai menyala',
  ] },
  'course-6': { hasGame: false, objectives: [
    'Menerapkan langkah dasar troubleshooting',
    'Mendiagnosis PC yang tidak menyala',
    'Membaca beep code dan gejala layar kosong',
  ] },
};

async function main() {
  const batch = db.batch();
  for (const [id, data] of Object.entries(extra)) {
    batch.update(db.collection('courses').doc(id), {
      ...data,
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  console.log(`Selesai: ${Object.keys(extra).length} course diperbarui.`);
}

main().catch((e) => { console.error(e); process.exit(1); });