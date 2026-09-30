import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiRepository {
  final String apiKey = "AQ.Ab8RN6Ia2VFdoaGlvrUX54t8MK4MuKilUfqv-pMYR9JcInjowQ";

  final List<String> _fallbackModels = [
    'gemini-3.8-flash',
    'gemini-3.5-flash-lite',
    'gemini-3.1-flash-lite',
    'gemini-flash-latest',
    'gemini-flash-lite-latest',
  ];

  Future<String> getAiResponse(String prompt) async {
    String lastError = '';

    for (final model in _fallbackModels) {
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');

      for (int attempt = 0; attempt < 2; attempt++) {
        try {
          if (attempt > 0) {
            await Future.delayed(Duration(milliseconds: 600 * attempt));
          }

          final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "contents": [
                {
                  "parts": [
                    {
                      "text":
                          "You are Study Brahmastra AI, a helpful tutor for students. Be concise, clear, and encouraging. User question: $prompt"
                    }
                  ]
                }
              ]
            }),
          );

          if (response.statusCode == 200) {
            final jsonResponse = jsonDecode(response.body);
            return jsonResponse['candidates'][0]['content']['parts'][0]['text'];
          }

          final jsonResponse = jsonDecode(response.body);
          lastError = jsonResponse['error']?['message'] ?? response.body;

          if (response.statusCode == 503 || response.statusCode == 429) {
            break;
          } else {
            throw Exception("Gemini Error (${response.statusCode}): $lastError");
          }
        } catch (e) {
          if (attempt == 1) rethrow;
        }
      }
    }

    throw Exception("All servers busy right now. Please try in 5 seconds. ($lastError)");
  }
}
