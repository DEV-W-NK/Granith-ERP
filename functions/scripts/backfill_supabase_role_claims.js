"use strict";

const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Aplica o claim `role=authenticated` aos usuarios existentes.
 * Necessario para o Supabase atribuir o papel `authenticated`.
 * @return {Promise<void>}
 */
async function backfillClaims() {
  let nextPageToken;
  let updated = 0;

  do {
    const result = await admin.auth().listUsers(1000, nextPageToken);
    for (const user of result.users) {
      const currentClaims = user.customClaims || {};
      if (currentClaims.role === "authenticated") {
        continue;
      }

      await admin.auth().setCustomUserClaims(user.uid, {
        ...currentClaims,
        role: "authenticated",
      });
      updated += 1;
      console.log(`claim atualizada para ${user.uid}`);
    }
    nextPageToken = result.pageToken;
  } while (nextPageToken);

  console.log(`backfill concluido: ${updated} usuario(s) atualizado(s)`);
}

backfillClaims()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
