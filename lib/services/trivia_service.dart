import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/question.dart';

class TriviaService {
  static const _baseUrl = 'https://quizapi.io/api/v1/questions';

  static Future<List<Question>> fetchQuestions({
    required String apiKey,
    int limit = 10,
    int offset = 0,
    String category = 'Programming',
    String difficulty = 'EASY',   // <-- this changes dynamically
    String type = 'MULTIPLE_CHOICE',
  }) async {
    if (apiKey.trim().isEmpty) throw Exception('Missing API key');

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'limit': '$limit',
      'offset': '$offset',
      'category': category,
      'difficulty': difficulty,
      'type': type,
      'random': 'true',
    });

    final response = await http
        .get(uri, headers: {'Authorization': 'Bearer $apiKey'})
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('HTTP error: ${response.statusCode}');
    }

    final body = json.decode(response.body) as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception('API returned success=false');
    }

    final data = body['data'] as List? ?? [];
    return data
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
