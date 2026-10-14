import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/chat_message.dart';

class GeminiRepository {
  final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  final List<String> _fallbackModels = [
    'gemini-3.8-flash',
    'gemini-3.6-flash',
    'gemini-3.5-flash-lite',
    'gemini-flash-latest',
  ];

  Future<String> getAiResponse(
      List<ChatMessage> history, String appContextSummary) async {
    String lastError = '';

    final recentHistory =
        history.length > 10 ? history.sublist(history.length - 10) : history;

    List<Map<String, dynamic>> contents = [];
    bool foundFirstUserMsg = false;

    for (var msg in recentHistory) {
      if (!foundFirstUserMsg && !msg.isUser) continue;
      foundFirstUserMsg = true;

      List<Map<String, dynamic>> parts = [];

      if (msg.text.isNotEmpty) {
        parts.add({"text": msg.text});
      }

      if (msg.base64Image != null) {
        parts.add({
          "inline_data": {
            "mime_type": "image/jpeg",
            "data": msg.base64Image,
          }
        });
      }

      contents.add({
        "role": msg.isUser ? "user" : "model",
        "parts": parts,
      });
    }

    final String rawSystemPrompt = r'''
You are Study Brahmastra AI, an autonomous study tutor and full app agent.

$appContextSummary

You can both ANSWER questions using the snapshot data above and EXECUTE app commands.

If the user gives an explicit command to add/toggle/delete/edit tasks, subjects, or notes, respond STRICTLY in JSON format with no extra text outside the JSON object:

1. Add Task:
{"action": "ADD_TASK", "title": "<title>", "subject": "<subject or General>", "reply": "<confirmation>"}

2. Complete/Toggle Task:
{"action": "TOGGLE_TASK", "title": "<task title or keyword>", "reply": "<confirmation>"}

3. Delete Task:
{"action": "DELETE_TASK", "title": "<task title or keyword>", "reply": "<confirmation>"}

4. Add Subject:
{"action": "ADD_SUBJECT", "subject": "<subject name>", "reply": "<confirmation>"}

5. Rename Subject:
{"action": "RENAME_SUBJECT", "oldSubject": "<current name>", "newSubject": "<new name>", "reply": "<confirmation>"}

6. Delete Subject:
{"action": "DELETE_SUBJECT", "subject": "<subject name>", "reply": "<confirmation>"}

7. Add Note:
{"action": "ADD_NOTE", "title": "<title>", "content": "<content>", "reply": "<confirmation>"}

8. Edit Note (Rename Title and/or Update Content):
{"action": "EDIT_NOTE", "oldTitle": "<current title or keyword>", "newTitle": "<new title>", "newContent": "<new content>", "reply": "<confirmation>"}

9. Delete Note:
{"action": "DELETE_NOTE", "title": "<note title or keyword>", "reply": "<confirmation>"}

CRITICAL FORMATTING & LATEX RULES:
1. Format all math expressions using standard LaTeX: use \(...\) for inline math (e.g., \(\bar{x}\), \(\mu\), \(H_0\), \(t\)) and $$\n...\n$$ for block display equations.
2. For matrices, systems of equations, and multiline math, use standard LaTeX environments with double backslashes for row breaks (e.g., $$\begin{pmatrix} 1 & 2 \\ 3 & 4 \end{pmatrix}$$).
3. NEVER use the '$' symbol for currency (dollars/rupees). Always write currency as 'Rs. 1.82' or 'USD 1.82' to prevent math tag collisions.
''';

    final String systemPrompt =
        rawSystemPrompt.replaceAll(r'$appContextSummary', appContextSummary);

    for (final model in _fallbackModels) {
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');

      try {
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                "system_instruction": {
                  "parts": [
                    {"text": systemPrompt}
                  ]
                },
                "contents": contents
              }),
            )
            .timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          final candidates = jsonResponse['candidates'];
          if (candidates != null && candidates.isNotEmpty) {
            final parts = candidates[0]['content']?['parts'];
            if (parts != null && parts.isNotEmpty) {
              return parts[0]['text'] ?? '';
            }
          }
        }

        final jsonResponse = jsonDecode(response.body);
        lastError = jsonResponse['error']?['message'] ?? response.body;
      } catch (e) {
        lastError = e.toString();
      }
    }

    throw Exception(
        "Astra AI is currently unavailable. Please check your API key in .env or internet connection. ($lastError)");
  }
}
