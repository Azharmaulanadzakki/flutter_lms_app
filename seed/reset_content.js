const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

const args = process.argv.slice(2);
const confirmed = args.includes('--yes');
const contentOnly = args.includes('--content-only');
const includeAr = args.includes('--include-ar');

// Konten pembelajaran.
const CONTENT = ['courses', 'materials', 'tests', 'questions', 'questionKeys'];
// Data belajar siswa yang menunjuk ke konten di atas.
const STUDENT_DATA = ['courseProgress', 'testAttempts', 'gameResults'];

const targets = [
  ...CONTENT,
  ...(contentOnly ? [] : STUDENT_DATA),
  ...(includeAr ? ['arItems'] : []),
];

async function countOf(name) {
  const snap = await db.collection(name).count().get();
  return snap.data().count;
}

async function main() {
  console.log(`Project : ${serviceAccount.project_id}`);
  console.log('');

  const before = {};
  let total = 0;
  for (const name of targets) {
    before[name] = await countOf(name);
    total += before[name];
    console.log(`${name.padEnd(16)}: ${before[name]} dokumen`);
  }

  console.log('');
  console.log('Dipertahankan : users, settings' + (includeAr ? '' : ', arItems'));
  console.log(`Total dihapus : ${total} dokumen`);

  if (!confirmed) {
    console.log('\nBelum ada yang dihapus. Pastikan nama project di atas benar,');
    console.log('lalu tambahkan --yes untuk menghapus permanen.');
    return;
  }
  if (total === 0) {
    console.log('\nTidak ada yang perlu dihapus.');
    return;
  }

  const writer = db.bulkWriter();
  let failures = 0;
  writer.onWriteError((err) => {
    if (err.failedAttempts < 3) return true; // coba ulang
    failures++;
    console.error(`Gagal menghapus ${err.documentRef.path}: ${err.message}`);
    return false;
  });

  for (const name of targets) {
    const refs = await db.collection(name).listDocuments();
    refs.forEach((ref) => writer.delete(ref));
  }
  await writer.close();

  console.log('\nHasil akhir:');
  for (const name of targets) {
    console.log(`${name.padEnd(16)}: ${await countOf(name)} dokumen tersisa`);
  }
  console.log(
    failures === 0
      ? '\nSelesai. Semua data yang dipilih sudah dihapus.'
      : `\nSelesai dengan ${failures} kegagalan. Jalankan ulang skrip untuk mencoba lagi.`,
  );
}

main().catch((e) => {
  console.error(e.message || e);
  process.exit(1);
});