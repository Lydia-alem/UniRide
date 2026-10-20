import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/user_model.dart';

class GemmaService {
  static const String baseUrl = AppConstants.backendUrl;

  Future<String> sendMessage(String message, {UserRole? role, String? context}) async {
    String systemContext = '';
    if (role == UserRole.student) {
      systemContext = '[Student context] ';
    } else if (role == UserRole.driver) {
      systemContext = '[Driver context] ';
    } else if (role == UserRole.admin) {
      systemContext = '[Admin context] ';
    }
    if (context != null && context.isNotEmpty) {
      systemContext += context + '\n\n';
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/api/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'message': message,
            'role': role?.name ?? 'student',
            'context': systemContext,
          }),
        )
        .timeout(const Duration(seconds: 90));

    if (response.statusCode != 200) {
      throw Exception(
        'AI request failed: ${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['reply'] as String;
  }

  Future<List<String>> getTripRecommendations({
    required String origin,
    required String destination,
    required String time,
    String? schedule,
  }) async {
    final prompt = '''
    As a university transport AI, recommend the best bus options for:
    - From: $origin
    - To: $destination
    - Preferred time: $time
    ${schedule != null ? '- Student schedule: $schedule' : ''}
    
    Provide 3 specific recommendations with timing and tips. Keep it concise.
    ''';

    final response = await sendMessage(prompt, role: UserRole.student);
    return response
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .take(10)
        .toList();
  }

  Future<String> getPeakHourPrediction(String routeId, String time) async {
    final prompt = '''
    Predict peak hours for a university bus route. 
    Route ID: $routeId, Typical time: $time.
    Is this a peak hour? What's the expected occupancy? Brief answer only.
    ''';
    return sendMessage(prompt, role: UserRole.student);
  }
}
