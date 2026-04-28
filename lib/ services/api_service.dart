import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/test_model.dart';
import '../screens/testing_screen.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.100:5000'; // Change to your IP

  Future<TestResult> testWebsite(String url, List<String> tests) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/test'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'url': url,
          'tests': tests,
        }),
      )
          .timeout(Duration(seconds: 30));


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TestResult.fromJson(data);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to test website: $e');
    }
  }

  Future<bool> checkServerStatus() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}