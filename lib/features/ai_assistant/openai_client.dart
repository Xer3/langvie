import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OpenAiClient {
  static const String _baseUrl =
      'https://europe-west1-langvie.cloudfunctions.net';

  final Dio _dio;

  OpenAiClient()
      : _dio = Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 60),
          ),
        );

  Future<String> chat({
    required List<Map<String, String>> messages,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Musisz być zalogowany, aby korzystać z asystenta AI.');
    }

    final token = await user.getIdToken();

    if (token == null || token.isEmpty) {
      throw Exception('Nie udało się pobrać tokenu użytkownika.');
    }

    try {
      final res = await _dio.post(
        '/aiChat',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'messages': messages,
        },
      );

      final data = res.data;
      final reply = data['reply'];

      if (reply is String && reply.trim().isNotEmpty) {
        return reply.trim();
      }

      throw Exception('Pusta odpowiedź z AI.');
    } on DioException catch (e) {
      final data = e.response?.data;

      if (data is Map && data['error'] is String) {
        throw Exception(data['error']);
      }

      throw Exception('Błąd połączenia z asystentem AI.');
    }
  }
}