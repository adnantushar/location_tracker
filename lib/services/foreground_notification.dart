import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:location_tracker/storage/user_storage.dart';
import 'package:location_tracker/data/repositories/auth_repository.dart';
import 'package:location_tracker/services/message_service.dart';

typedef OnNotificationTap = void Function(int senderId, int receiverId);

class ForegroundMessageNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  static final MessageService _messageService = MessageService();
  static final AuthRepository _authRepository = AuthRepository();
  static OnNotificationTap? onNotificationTap;

  static Future<void> initialize({
    required OnNotificationTap onNotificationTapCallback,
  }) async {
    onNotificationTap = onNotificationTapCallback;

    try {
      // Request permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print('Permission: ${settings.authorizationStatus}');

      // Android initialization settings
      const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings (Darwin)
      const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Combined initialization settings
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings, // <-- Add iOS settings here
      );

      // Initialize local notifications plugin
      await _localNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          print('Notification tapped: ${response.payload}');
          if (response.payload != null) {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            final int senderId = int.parse(data['senderId']);
            final int receiverId = int.parse(data['receiverId']);
            onNotificationTap?.call(senderId, receiverId);
          }
        },
      );

      // Get user ID and set up message stream listener
      final int? userId = await UserStorage.getUserId();
      if (userId != null) {
        _setupMessageStreamListener(userId);
      } else {
        print('User ID is null; cannot set up message listener');
      }

      // Listen for foreground Firebase messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print(
          'Foreground Message Received: ${message.notification?.title} - ${message.notification?.body}',
        );
        _handleForegroundMessage(message);
      });

      // Log FCM token
      final token = await _messaging.getToken();
      print('FCM Token: $token');
    } catch (e) {
      print('Error initializing Firebase notifications: $e');
    }
  }

  static void _setupMessageStreamListener(int userId) {
    final currentUserMessagesStream = _messageService.getAllMessages(userId);
    currentUserMessagesStream.listen(
          (allMessagesMap) async {
        final allMessages =
        allMessagesMap.values.expand((list) => list).toList();
        final receivedMessages =
        allMessages
            .where(
              (message) =>
          message.receiverId == userId &&
              userId != message.senderId &&
              !message.isRead,
        )
            .toList();

        if (receivedMessages.isNotEmpty) {
          for (var message in receivedMessages) {
            print('New unread message detected: ${message.content}');
            final receiverInfo = await _authRepository.getUser(
              message.senderId,
            );
            showLocalNotification(
              title: '${receiverInfo.fullname} Sent a Message',
              body: message.content,
              payload: jsonEncode({
                'senderId': message.senderId.toString(),
                'receiverId': message.receiverId.toString(),
              }),
            );
          }
        }
      },
      onError: (error) {
        print('Error in message stream: $error');
      },
    );
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification != null) {
      showLocalNotification(
        title: message.notification!.title ?? 'New Message',
        body: message.notification!.body ?? 'You have a new message',
      );
    } else if (message.data.isNotEmpty) {
      showLocalNotification(
        title: message.data['title'] ?? 'New Message',
        body:
        message.data['body'] ??
            message.data['content'] ??
            'You have a new message',
      );
    }
  }

  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
        'message_channel',
        'Messages',
        channelDescription: 'This channel is for message notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification'),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await _localNotificationsPlugin.show(
        notificationId,
        title,
        body,
        platformDetails,
        payload: payload,
      );
      print('Local notification shown: $title - $body (ID: $notificationId)');
    } catch (e) {
      print('Error showing local notification: $e');
      const AndroidNotificationDetails fallbackDetails =
      AndroidNotificationDetails(
        'message_channel',
        'Messages',
        channelDescription: 'This channel is for message notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      );
      const DarwinNotificationDetails fallbackIosDetails =
      DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const NotificationDetails fallbackPlatformDetails = NotificationDetails(
        android: fallbackDetails,
        iOS: fallbackIosDetails,
      );

      await _localNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        fallbackPlatformDetails,
        payload: payload,
      );
      print('Fallback notification shown: $title - $body');
    }
  }
}