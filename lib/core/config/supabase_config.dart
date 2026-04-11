class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const useFirebaseAuthEmulator =
      bool.fromEnvironment(
        'USE_FIREBASE_AUTH_EMULATOR',
        defaultValue: false,
      );

  static bool get isConfigured =>
      url.isNotEmpty && publishableKey.isNotEmpty;

  static void validate() {
    if (!isConfigured) {
      throw StateError(
        'Supabase nao configurado. Informe SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY via --dart-define.',
      );
    }
  }
}
