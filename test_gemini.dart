// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

void main() async {
  final envLines = File('.env').readAsLinesSync();
  String? apiKey;
  for (var line in envLines) {
    if (line.startsWith('GEMINI_API_KEY=')) {
      apiKey = line.split('=')[1].trim();
      break;
    }
  }

  if (apiKey == null || apiKey.isEmpty) {
    print('No API KEY');
    return;
  }
  
  final response = await http.post(
    Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent'),
    headers: {
      'x-goog-api-key': apiKey,
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'systemInstruction': {
        'parts': [{'text': 'test'}],
      },
      'contents': [
        {'role': 'user', 'parts': [{'text': 'hola'}]}
      ],
      'generationConfig': {
        'temperature': 0.5,
        'maxOutputTokens': 4096,
      },
    }),
  );

  print('Status: ${response.statusCode}');
  print('Body: ${response.body}');
}
