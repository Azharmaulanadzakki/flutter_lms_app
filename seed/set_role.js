const { initializeApp, cert } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const serviceAccount = require("./serviceAccountKey.json");

initializeApp({ credential: cert(serviceAccount) });

const VALID = ["student", "teacher", "admin", "superadmin"];
const [email, role] = process.argv.slice(2);

async function main() {
  if (!email || !VALID.includes(role)) {
    console.log(
      "Pemakaian: node set_role.js email@contoh.com <student|teacher|admin|superadmin>",
    );
    process.exit(1);
  }

  const user = await getAuth().getUserByEmail(email);
  const ref = getFirestore().collection("users").doc(user.uid);
  const snap = await ref.get();

  if (snap.exists) {
    await ref.update({ role, updatedAt: FieldValue.serverTimestamp() });
  } else {
    await ref.set({
      name: user.displayName || email.split("@")[0],
      email,
      role,
      photoUrl: null,
      isActive: true,
      createdAt: FieldValue.serverTimestamp(),
      lastLogin: FieldValue.serverTimestamp(),
    });
  }
  console.log(`Selesai: ${email} sekarang berperan ${role}.`);
}

main().catch((e) => {
  console.error(e.message || e);
  process.exit(1);
});
