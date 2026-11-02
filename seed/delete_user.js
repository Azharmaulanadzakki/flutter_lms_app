const { initializeApp, cert } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");
const serviceAccount = require("./serviceAccountKey.json");

initializeApp({ credential: cert(serviceAccount) });
const auth = getAuth();
const db = getFirestore();

const args = process.argv.slice(2);
const email = args.find((a) => !a.startsWith("--"));
const confirmed = args.includes("--yes");
const force = args.includes("--force");

// Koleksi yang menyimpan data milik pengguna lewat field `userId`.
const OWNED = ["courseProgress", "testAttempts", "gameResults"];

async function main() {
  if (!email) {
    console.log(
      "Pemakaian: node delete_user.js email@contoh.com [--yes] [--force]",
    );
    process.exit(1);
  }

  const user = await auth.getUserByEmail(email);
  const profile = await db.collection("users").doc(user.uid).get();
  const role = profile.exists ? profile.data().role : "(tanpa profil)";

  const owned = {};
  for (const name of OWNED) {
    owned[name] = await db
      .collection(name)
      .where("userId", "==", user.uid)
      .get();
  }

  console.log(`Akun   : ${email} (uid ${user.uid})`);
  console.log(`Role   : ${role}`);
  for (const name of OWNED)
    console.log(`${name.padEnd(15)}: ${owned[name].size} dokumen`);

  if (role === "superadmin" && !force) {
    console.log("Akun super admin tidak dihapus tanpa --force.");
    process.exit(1);
  }
  if (!confirmed) {
    console.log(
      "\nBelum ada yang dihapus. Tambahkan --yes untuk menghapus permanen.",
    );
    return;
  }

  const writer = db.bulkWriter();
  for (const name of OWNED)
    owned[name].docs.forEach((d) => writer.delete(d.ref));
  writer.delete(db.collection("users").doc(user.uid));
  await writer.close();
  await auth.deleteUser(user.uid);

  console.log("\nSelesai: akun, profil, dan data belajarnya sudah dihapus.");
}

main().catch((e) => {
  console.error(e.message || e);
  process.exit(1);
});


// Petunjuk Pemakaian: IKI PENTING!!!
// cd seed 
// node delete_user.js siswa@contoh.com          # hanya menampilkan apa yang akan dihapus
// node delete_user.js siswa@contoh.com --yes    # menghapus permanen
// cd ..