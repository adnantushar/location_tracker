import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:location_tracker/config/api_config.dart';
import 'package:location_tracker/data/models/colgis_message.dart';
// import '../models/message.dart';
import 'package:location_tracker/storage/secure_storage.dart';

class ColgisMessageRepository {
  final String baseUrl = ApiConfig.baseUrl;

  Future<void> sendMessage(int receiverId, String content, int senderId) async {
    try {
      final token = await SecureStorage.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/send-message'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          'senderid': senderId,
          'receiverid': receiverId,
          'content': content,
        }),
      );
      if (response.statusCode == 201 || response.statusCode == 422) {
        return jsonDecode(response.body);
      } else {
        final errorResponse = jsonDecode(response.body);
        throw Exception(errorResponse['message'] ?? 'Failed to sent message');
      }
    } catch (e) {
      if (kDebugMode) print('Error sending message: $e');
      rethrow;
    }
  }

  Future<List<ColgisMessage>> getInitialMessages(
      int senderId,
      int receiverId,
      ) async {
    try {
      final token = await SecureStorage.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/getInitialMessages/$senderId/$receiverId'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        return data.map((e) => ColgisMessage.fromJson(e)).toList();
      } else {
        throw Exception('User location not found');
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching initial messages: $e');
      return [];
    }
  }

  Stream<List<ColgisMessage>> getMessages(int senderId, int receiverId) async* {
    while (true) {
      try {
        final token = await SecureStorage.getToken();
        final response = await http.get(
          Uri.parse('$baseUrl/getMessages/$senderId/$receiverId'),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json"
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body)['data'] as List;
          yield data.map((e) => ColgisMessage.fromJson(e)).toList();
        } else {
          yield [];
        }
      } catch (e) {
        if (kDebugMode) print('Error setting up message stream: $e');
        yield [];
      }
      await Future.delayed(const Duration(seconds: 3)); // Poll every 3 seconds
    }
  }
}