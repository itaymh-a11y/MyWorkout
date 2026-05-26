/**
 * טעינת תרגילים מובנים ל-Firestore (פעם אחת).
 *
 * דרישות:
 *   npm install firebase-admin
 *   משתנה סביבה GOOGLE_APPLICATION_CREDENTIALS מצביע ל-Service Account JSON
 *
 * הרצה:
 *   node scripts/seed-builtin.mjs
 */
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import admin from 'firebase-admin';

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectId = process.env.FIREBASE_PROJECT_ID ?? 'myworkout-f6236';

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId,
  });
}

const db = admin.firestore();
const jsonPath = join(__dirname, '../assets/seed/builtin_exercises.json');
const exercises = JSON.parse(readFileSync(jsonPath, 'utf8'));

async function seed() {
  const batch = db.batch();
  let count = 0;

  for (const item of exercises) {
    const { id, ...data } = item;
    const ref = db.collection('builtin_exercises').doc(id);
    batch.set(ref, data, { merge: true });
    count++;
  }

  await batch.commit();
  console.log(`✓ Seeded ${count} builtin exercises into builtin_exercises`);
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
