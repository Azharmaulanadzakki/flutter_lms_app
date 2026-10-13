const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

async function main() {
  await db.collection('settings').doc('progressWeights').set({
    preTest: 10,
    materials: 40,
    game: 30,
    postTest: 20,
    updatedAt: FieldValue.serverTimestamp(),
  });
  console.log('Selesai: settings/progressWeights dibuat (10 / 40 / 30 / 20).');
}

main().catch((e) => { console.error(e); process.exit(1); });