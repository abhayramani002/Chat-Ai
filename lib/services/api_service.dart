import 'dart:convert';
import 'package:chat_ai/utils/config.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static final String _apiUrl = OpenAIConfig.openAiApiEndpoint;
  static final String _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

  static Future<String> fetchAiResponseFromOpenAI(
      List<Map<String, String>> messages) async {
    if (_apiKey.isEmpty || _apiUrl.isEmpty) {
      return "API configuration is missing. Please check your environment variables.";
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_apiKey",
        },
        body: jsonEncode({
          "model": OpenAIConfig.gptModel,
          "messages": messages,
          "max_tokens": OpenAIConfig.maxTokens,
          "temperature": OpenAIConfig.temperature
        }),
      );
      if (response.statusCode == 200) {
        final aiResponseData = jsonDecode(response.body);
        return aiResponseData['choices'][0]['message']['content'] ??
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
