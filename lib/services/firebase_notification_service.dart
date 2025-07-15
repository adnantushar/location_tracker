import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:location_tracker/bloc/chat_screen/chat_screen_bloc.dart';
import 'package:location_tracker/bloc/chat_screen/chat_screen_event.dart';

// A global key for Navigator, usually defined in main.dart
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// TOP-LEVEL FUNCTION for handling Firebase Messaging background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background,
  // such as Firestore or Realtime Database, make sure you call `initializeApp`
  // before using other Firebase services.
  // await Firebase.initializeApp(); // Assuming it's already initialized in main()
  print('Handling a background message: ${message.messageId}');
  // For simplicity, we'll let FCM handle displaying the basic notification for background/terminated.
  // If you need to show a local notification for a background FCM message,
  // you'd typically fetch the FlutterLocalNotificationsPlugin instance here
  // and call .show().
}

// TOP-LEVEL FUNCTION for handling Flutter Local Notifications background responses
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  print('Background notification response (local notification): ${notificationResponse.payload}');
  // You can navigate or perform other actions here based on the payload
  // if the app is woken up by a local notification tap.
  // Note: navigatorKey might not be directly available or reliable in a pure background context.
  // You might need a different mechanism for deep linking from background.
}

class FirebaseNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize(BuildContext context) async {
    // Request permission for iOS
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Register background message handler for FCM
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Setup foreground notification presentation options
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize flutter_local_notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher'); // Your app icon

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap when app is in foreground/background (local notification)
        if (response.payload != null) {
          print('Notification payload: ${response.payload}');
          // Example: Navigate to chat screen
          navigatorKey.currentState?.pushNamed('/home');
          // Note: Accessing Bloc from here directly is problematic if context is not guaranteed.
          // It's better to handle "mark as read" on ChatScreen's initState/didChangeAppLifecycleState.
        }
      },
      // Pass the TOP-LEVEL function for background notification responses
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Listen for messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel', // id - MUST MATCH THE CHANNEL ID IN main.dart
              'High Importance Notifications', // title
              channelDescription: 'This channel is used for important notifications.',
              icon: android.smallIcon,
              // other properties like sound, color, etc.
            ),
          ),
          payload: 'chat_message_payload', // Optional payload for handling taps
        );
      }
    });

    // Handle interaction when the app is opened from a terminated state
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App opened from terminated state by notification: ${message.data}');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.pushNamed('/home');
        });
      }
    });

    // Handle interaction when the app is opened from a background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from background by notification: ${message.data}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushNamed('/home');
      });
    });

    // Get FCM token (useful for sending targeted notifications from your backend)
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');
    // You should save this token to your database associated with the user's ID
    // so your backend knows where to send notifications.
  }
}
//ddSb3f9_T4ieCYcg72nDDk:APA91bF_Dfc5sG7FPMJrOM5GM7oVkOck7ZXJwUoXV0tJLaptWP9RAP3x3MOLQ2-tC2sWSO1CxQWlJuxCgZ3fNhmAyoZ-jNZWPmkU5Lf_5D8G-dC1xbjMzB0