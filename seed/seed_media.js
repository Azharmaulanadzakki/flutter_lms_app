const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

// Isi link di bawah. Yang dibiarkan kosong ('') dilewati.
// video : link YouTube biasa (watch?v=..., youtu.be/..., atau shorts)
// pdf   : link Google Drive (Share -> Anyone with the link) atau URL .pdf
const media = {
  'course-1-m3': 'course-1-m3', // video
  'course-1-m4': 'course-1-m4', // pdf
  'course-2-m3': 'course-2-m3', // video
  'course-2-m4': 'course-2-m4', // pdf
  'course-3-m4': 'course-3-m4', // video
  'course-4-m3': 'course-4-m3', // video
  'course-5-m4': 'course-5-m4', // video
  'course-5-m5': 'course-5-m5', // pdf
  'course-6-m4': 'course-6-m4', // video
};

async function main() {
  const batch = db.batch();
  let count = 0;

  for (const [id, url] of Object.entries(media)) {
    if (!url.trim()) continue;
    batch.update(db.collection('materials').doc(id), {
      mediaUrl: url.trim(),
      isPublished: true,
      updatedAt: FieldValue.serverTimestamp(),
    });
    count++;
  }

  if (count === 0) {
    console.log('Belum ada link yang diisi. Isi objek "media" di seed_media.js dulu.');
    return;
  }

  await batch.commit();
  console.log(`Selesai: ${count} materi diperbarui dan dipublish.`);
}

main().catch((e) => { console.error(e); process.exit(1); });