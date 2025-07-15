import 'dart:io';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:location_tracker/screens/auth/login.dart';
import 'package:location_tracker/screens/message/chat_screen.dart';
import 'package:location_tracker/bloc/auth/auth_bloc.dart';
import 'package:location_tracker/bloc/auth/auth_event.dart';
import 'package:location_tracker/bloc/location/location_bloc.dart';
import 'package:location_tracker/data/repositories/auth_repository.dart';
import 'package:location_tracker/data/repositories/user_location_repository.dart';
import 'package:location_tracker/services/message_service.dart';
import 'package:location_tracker/storage/secure_storage.dart';
import 'package:location_tracker/services/firebase_notification_service.dart';


// Global Navigator Key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Define a top-level function to create the Android Notification Channel
// This is required for heads-up notifications on Android 8.0+
late AndroidNotificationChannel channel;
bool isFlutterLocalNotificationsInitialized = false;

Future<void> setupFlutterNotifications() async {
  if (isFlutterLocalNotificationsInitialized) {
    return;
  }
  channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.max,
  );

  await FlutterLocalNotificationsPlugin()
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  isFlutterLocalNotificationsInitialized = true;
}


// void main() async{
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   // DartPluginRegistrant.ensureInitialized();
//   // await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//   // await initializeFirebaseMessaging();
//
//   // Initialize notifications before runApp
//   await setupFlutterNotifications();
//
//   await LocationServiceBloc.configureBackgroundService();// Call static method from Bloc
//
//   // await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
//
//   // Define the onNotificationTap callback
//   // onNotificationTap(int senderId, int receiverId) async {
//   //   final userId = await SecureStorage.getUserId();
//   //   if (userId == null) {
//   //     navigatorKey.currentState?.pushReplacementNamed('/auth');
//   //   } else {
//   //     navigatorKey.currentState?.push(
//   //       MaterialPageRoute(
//   //         builder:
//   //             (_) => ChatScreen(),
//   //       ),
//   //     );
//   //   }
//   // }
//
//   // Initialize notification services
//   // await initializeService(onNotificationTap: onNotificationTap);
//   // await ForegroundMessageNotificationService.initialize(
//   //   onNotificationTapCallback: onNotificationTap,
//   // );
//
//   runApp(
//     MultiBlocProvider(
//       providers: [
//         BlocProvider(
//           create:
//               (context) =>
//           AuthBloc(AuthRepository())
//             ..add(CheckLoginStatusEvent()),
//         ),
//         BlocProvider(
//           // Create the Bloc
//           create: (context) => LocationServiceBloc(UserLocationRepository()), // Inject LocationBloc here
//         ),
//       ],
//       child: MultiRepositoryProvider(
//         providers: [
//           // RepositoryProvider(create: (_) => UserLocationRepository()),
//           RepositoryProvider(create: (_) => AuthRepository()),
//           // RepositoryProvider(create: (_) => MatchUsersRepository()),
//           // RepositoryProvider(create: (_) => UserService()),
//           RepositoryProvider(create: (_) => MessageService()),
//         ],
//         child: MaterialApp(
//           debugShowCheckedModeBanner: false,
//           // navigatorKey: navigatorKey,
//           // locale: const Locale('ja', 'JP'),
//           // supportedLocales: const [Locale('ja', 'JP'), Locale('en', 'US')],
//           // localizationsDelegates: [
//           //   // Removed const
//           //   GlobalMaterialLocalizations.delegate,
//           //   GlobalWidgetsLocalizations.delegate,
//           //   GlobalCupertinoLocalizations.delegate,
//           // ],
//           title: 'Flutter Auth with BLoC',
//           theme: ThemeData(primarySwatch: Colors.blue),
//           initialRoute: '/auth',
//           routes: {
//             '/auth': (context) => AuthScreen(),
//             '/home': (context) => const ChatScreen(),
//           },
//           // onGenerateRoute: (settings) {
//           //   if (settings.name == '/chat') {
//           //     final args = settings.arguments as Map<String, dynamic>?;
//           //     if (args != null) {
//           //       return MaterialPageRoute(
//           //         builder:
//           //             (_) => ChatScreen(
//           //           senderId: args['senderId'],
//           //           receiverId: args['receiverId'],
//           //           route: args['route'],
//           //         ),
//           //       );
//           //     }
//           //   }
//           //   return null;
//           // },
//         ),
//       ),
//     ),
//   );
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize notifications before runApp
  await setupFlutterNotifications();

  await LocationServiceBloc.configureBackgroundService(); // Call static method from Bloc

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(create: (_) => AuthRepository()),
        RepositoryProvider<UserLocationRepository>(create: (_) => UserLocationRepository()),
        // RepositoryProvider<ChatRepository>(create: (_) => ChatRepository()),
        RepositoryProvider(create: (_) => MessageService()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              context.read<AuthRepository>(),
            )..add(CheckLoginStatusEvent()),
          ),
          BlocProvider<LocationServiceBloc>(
            create: (context) => LocationServiceBloc(
              context.read<UserLocationRepository>(),
            ),
          ),
          // BlocProvider<ChatBloc>(
          //   create: (context) => ChatBloc(chatRepository: context.read<ChatRepository>()),
          // ),
        ],
        child: const MyApp(), // MyApp is now a StatefulWidget
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final FirebaseNotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService = FirebaseNotificationService();
    // Initialize with context. This context is available because MyApp is a widget.
    _notificationService.initialize(context);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // Assign the global key here
      title: 'Flutter Auth with BLoC',
      theme: ThemeData(primarySwatch: Colors.blue),
      // Use BlocBuilder to decide the initial route based on AuthState
      initialRoute: '/auth',
      routes: {
        '/auth': (context) => AuthScreen(),
        '/home': (context) => const ChatScreen(),
      },
    );
  }
}