class AppConfig {
  static const quizApiKey =
      String.fromEnvironment('QUIZ_API_KEY');

  static void validate() {
    if (quizApiKey.isEmpty) {
      throw Exception(
        'Missing QUIZ_API_KEY. Run with --dart-define.',
      );
    }
  }
}
