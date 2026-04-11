const admin = require("firebase-admin");
const {setGlobalOptions} = require("firebase-functions");
const {
  beforeUserCreated,
  beforeUserSignedIn,
} = require("firebase-functions/v2/identity");

admin.initializeApp();

setGlobalOptions({maxInstances: 10});

exports.supabaseRoleOnCreate = beforeUserCreated(() => {
  return {
    customClaims: {
      role: "authenticated",
    },
  };
});

exports.supabaseRoleOnSignIn = beforeUserSignedIn(() => {
  return {
    customClaims: {
      role: "authenticated",
    },
  };
});
