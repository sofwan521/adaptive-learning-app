/// Konstanta bersama AdaptiLearn.
abstract final class AppConstants {
  static const String appName = 'AdaptiLearn';

  /// Kunci --dart-define untuk Supabase.
  static const String supabaseUrlKey = 'SUPABASE_URL';
  static const String supabaseAnonKeyKey = 'SUPABASE_ANON_KEY';

  /// Kebijakan adaptif sesuai AGENTS.md.
  static const int minQuestionsForMastery = 4;
  static const int maxQuestionsPerConcept = 8;
  static const double seThreshold = 0.6;
  static const int consecutiveWrongForEarlyStop = 3;

  /// Grid EAP sesuai AGENTS.md.
  static const double eapMin = -4.0;
  static const double eapMax = 4.0;
  static const double eapStep = 0.1;
}
