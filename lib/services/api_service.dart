import 'dart:convert';
import 'package:chat_ai/utils/config.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static final String apiUrl = Config.openAiApiEndpoint;
  static final String apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

  static Future<String> fetchAiResponse(
      List<Map<String, String>> messages) async {
    if (apiKey.isEmpty || apiUrl.isEmpty) {
      return "API configuration is missing. Please check your environment variables.";
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode({
          "model": Config.gptModal,
          "messages": messages,
          "max_tokens": Config.maxTokens,
          "temperature": Config.temperature
        }),
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['choices'][0]['message']['content'] ??
            "No response";
      } else {
        print("Error response: ${response.body}");
        return "Failed to get a response from AI: ${response.body}";
      }
    } catch (error) {
      return "An error occurred. Please try again later.";
    }
  }
}
