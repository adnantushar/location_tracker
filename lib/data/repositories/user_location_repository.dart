import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker/config/api_config.dart';
import 'package:location_tracker/storage/secure_storage.dart';


class UserLocationRepository {
  final String baseUrl = ApiConfig.baseUrl;
  final http.Client _client;

  UserLocationRepository({http.Client? client})
      : _client = client ?? http.Client();

  Future<void> updateUserLocation(double latitude, double longitude) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      throw Exception('No internet connection.');
    }

    final uri = Uri.parse('$baseUrl/userlocation');
    final token = await SecureStorage.getToken();
    const int maxRetries = 3;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _client.post(
          uri,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json"
          },
          // body: jsonEncode(userLocation.toJson()),
          body: '{"endlatitude": $latitude, "endlongitude": $longitude}'
        );

        if (response.statusCode == 200) {
          print('------User location updated successfully.----');
          return;
        }

        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? 'Unknown error occurred.';
        throw Exception('Update failed: $errorMessage');
      } catch (e) {
        if (attempt == maxRetries) {
          print('❌ Final attempt failed: $e');
          throw Exception('Error updating location: $e');
        } else {
          print('⚠️ Attempt $attempt failed: $e. Retrying...');
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
  }

  // Future<void> deleteUserLocation(int id) async {
  //   final response = await http.delete(Uri.parse('$baseUrl/$id'));
  //
  //   if (response.statusCode != 200) {
  //     throw Exception('Failed to delete user location');
  //   }
  // }
}
