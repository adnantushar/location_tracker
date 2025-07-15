import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:location_tracker/config/api_config.dart';
import 'package:location_tracker/data/models/user.dart';
import 'package:location_tracker/storage/secure_storage.dart';

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

  Future<bool> validateToken(String token) async {
    int maxRetries = 3;
    for (int i = 0; i < maxRetries; i++) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/validate-token'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final decodedResponse = jsonDecode(response.body);
          return decodedResponse['valid'] == true;
        } else {
          return false;
        }
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    throw Exception('Max retries reached');
  }

  Future<List<User>> getAllUsers() async {
    int maxRetries = 3;
    for (int i = 0; i < maxRetries; i++) {
      try {
        final token = await SecureStorage.getToken();
        final response = await http.get(
            Uri.parse('$baseUrl/users'),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json"
            },
        );

        if (response.statusCode == 200) {
          final responseBody = jsonDecode(response.body);

          if (responseBody.containsKey('users') &&
              responseBody['users'] is List) {
            final data = responseBody['users'] as List;
            return data.map((e) => User.fromJson(e)).toList();
          } else {
            throw Exception('Invalid API response format');
          }
        } else {
          throw Exception(
            'Failed to load user locations: ${response.statusCode}',
          );
        }
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    throw Exception('Max retries reached');
  }

  Future<User> getUser(int userId) async {
    int maxRetries = 3;
    for (int i = 0; i < maxRetries; i++) {
      try {
        final token = await SecureStorage.getToken();
        final response = await http.get(
            Uri.parse('$baseUrl/user/$userId'),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json"
            },
        );

        if (response.statusCode == 200) {
          final responseBody = jsonDecode(response.body);

          if (responseBody.containsKey('user') && responseBody['user'] is Map) {
            final userData = responseBody['user'] as Map<String, dynamic>;
            return User.fromJson(userData);
          } else {
            throw Exception(
              'Invalid API response format: Expected "user" key with a map value',
            );
          }
        } else {
          throw Exception('Failed to load user: ${response.statusCode}');
        }
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    throw Exception('Max retries reached');
  }

}