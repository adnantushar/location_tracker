import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:location_tracker/config/api_config.dart';
import 'package:location_tracker/data/models/user.dart';

class AuthRepository {
  final String baseUrl = ApiConfig.baseUrl;

  Future<Map<String, dynamic>> register(User user) async{
    int maxRetries = 3;
    for (int i = 0; i < maxRetries; i++){
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/register'),
          headers: {'Content-type': 'application/json'},
          body: jsonEncode(user.toJson())
        );
        if (response.statusCode == 201 || response.statusCode == 422){
          return jsonDecode(response.body);
        } else {
          final errorResponse = jsonDecode(response.body);
          throw Exception(
            errorResponse['message'] ?? 'Failed to register user',
          );
        }
      }
      catch (e) {
        if (i == maxRetries - 1) rethrow;
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    throw Exception('Max retries reached');
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    int maxRetries = 3;
    for (int i = 0; i < maxRetries; i++) {
      try {
        final uri = Uri.parse(
          '$baseUrl/login',
        ).replace(queryParameters: {'email': email, 'password': password});

        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final decodedResponse = jsonDecode(response.body);
          return decodedResponse;
        } else {
          throw Exception('Invalid credentials');
        }
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    throw Exception('Max retries reached');
  }

}