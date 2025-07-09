import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location_tracker/screens/auth/login.dart';
import 'package:location_tracker/screens/message/chat_screen.dart';
import 'package:location_tracker/bloc/auth/auth_bloc.dart';
import 'package:location_tracker/bloc/auth/auth_event.dart';
import 'package:location_tracker/bloc/location/location_bloc.dart';
import 'package:location_tracker/data/repositories/auth_repository.dart';
import 'package:location_tracker/data/repositories/user_location_repository.dart';
// import 'package:location_tracker/services/background_location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


// Global ValueNotifier to manage service running state across UI
final ValueNotifier<bool> isServiceRunningNotifier = ValueNotifier<bool>(false);

// Global notification plugin instance
final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

// --- Background Service Control Functions (called from UI and background) ---

void startLocationService() async {
  final service = FlutterBackgroundService();
  if (await service.isRunning()) {
    print("Background service already running (from startLocationService)");
    isServiceRunningNotifier.value = true;
    return;
  }
  await service.startService();
  isServiceRunningNotifier.value = true;
  print("Background service started (from startLocationService)");
}

void stopLocationService() {
  final service = FlutterBackgroundService();
  service.invoke("stop");
  isServiceRunningNotifier.value = false;
  print("Background service stopped (from stopLocationService)");
}

// --- Notification Channel Setup ---

Future<void> _createNotificationChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'location_channel',
    'Location Tracking',
    description: 'This channel is used for background location tracking',
    importance: Importance.low, // Lower importance for less intrusive notification
    playSound: false,
    enableLights: false,
    enableVibration: false,
  );

  await _localNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

// --- Background Service Initialization ---

Future<void> initializeService() async {
  WidgetsFlutterBinding.ensureInitialized(); // Essential for plugin initialization

  // Initialize notification plugin
  const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings = InitializationSettings(android: androidInit);
  await _localNotificationsPlugin.initialize(initSettings);

  await _createNotificationChannel(); // Create the notification channel

  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false, // Set to false, we'll start it manually after permissions
      isForegroundMode: true,
      notificationChannelId: 'location_channel',
      initialNotificationTitle: 'Location Tracking',
      initialNotificationContent: 'Tracking in background',
      foregroundServiceNotificationId: 888,
      foregroundServiceTypes: [AndroidForegroundType.location],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false, // Set to false for iOS as well, handle start manually
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  // Update the notifier based on the actual service running status
  isServiceRunningNotifier.value = await service.isRunning();
  print("Service running status after initialization: ${isServiceRunningNotifier.value}");
}

// --- Permission and Location Service Checker for the UI ---
// This function shows dialogs and guides the user.
Future<bool> requestAndCheckLocationPermissions(BuildContext context) async {
  bool serviceEnabled;
  LocationPermission permission;

  // 1. Check if location services are enabled
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Show dialog and prompt to open settings
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Location Services Disabled"),
          content: const Text(
              "Please enable location services to allow the app to track your location."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Geolocator.openLocationSettings(); // Open location settings
              },
              child: const Text("Open Settings"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
    return false;
  }

  // 2. Check and request location permission (Foreground)
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      await showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text("Location Permission Required"),
            content: const Text(
                "Location permission is required to track your location. Please grant it."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
      return false; // User denied foreground permission
    }
  }

  // 3. Check for permanently denied permissions
  if (permission == LocationPermission.deniedForever) {
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Location Permission Permanently Denied"),
          content: const Text(
              "Location permission was permanently denied. Please go to app settings and enable 'Always Allow' for background tracking."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Geolocator.openAppSettings(); // Open app settings
              },
              child: const Text("Open App Settings"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
    return false;
  }

  // 4. Crucial: Check for 'Always Allow' for background tracking (Android 10+)
  // If permission is only 'whileInUse', inform the user to upgrade it.
  if (permission == LocationPermission.whileInUse) {
    // Attempt to request "Always" (this might directly open settings on Android 10+)
    permission = await Geolocator.requestPermission(); // Request again, hoping for 'always' option
    if (permission != LocationPermission.always) {
      await showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text("Background Location Needed"),
            content: const Text(
                "For continuous location tracking in the background, please change the location permission to 'Always Allow' in app settings."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Geolocator.openAppSettings(); // Open app settings
                },
                child: const Text("Open App Settings"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text("Cancel"),
              ),
            ],
          );
        },
      );
      return false; // Not 'always', so background tracking won't be fully effective
    }
  }

  // If we reach here, permission is 'always' and service is enabled
  return true;
}

// --- Background Isolate Entry Points ---

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // IMPORTANT:
  // - Do NOT call WidgetsFlutterBinding.ensureInitialized() here for Android.
  //   It's handled by flutter_background_service itself.
  // - Do NOT call DartPluginRegistrant.ensureInitialized() here for Android.
  //   It's handled by flutter_background_service itself.

  // final SharedPreferences prefs = await SharedPreferences.getInstance();
  final UserLocationRepository _locationRepo = UserLocationRepository();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService(); // Ensure it's foreground

    service.on("stop").listen((event) {
      service.stopSelf();
      print("Background service stopped (from onStart)");
    });
  }

  // Initial check for permissions in background. If not 'always', log and return.
  // DO NOT request permissions from here.
  LocationPermission currentPermission = await Geolocator.checkPermission();
  bool canTrackBackground = (currentPermission == LocationPermission.always);

  if (!canTrackBackground) {
    print("Background service started, but 'Always Allow' location permission not initially granted. Location updates might be limited or fail.");
    // Optionally, if service absolutely cannot run without 'always', you can stop it here.
    // service.stopSelf();
    // return;
  }

  Timer.periodic(const Duration(seconds: 30), (timer) async {
    print("Background task running now at ${DateTime.now()}");

    // Re-check permission within the loop, but only check, don't request.
    // This handles scenarios where the user might revoke permission while the service is running.
    currentPermission = await Geolocator.checkPermission();
    if (currentPermission != LocationPermission.always) {
      print("Background permission not (or no longer) 'Always Allow'. Skipping location update.");
      // If permission is revoked while running, stop the service gracefully
      service.stopSelf();
      timer.cancel();
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled. Cannot get location in background.");
      // The background service cannot enable it. User must do it from UI.
      service.stopSelf();
      timer.cancel();
      return;
    }

    try {
      final LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      );
      final Position position = await Geolocator.getCurrentPosition(locationSettings: locationSettings);

      print("Got position: $position");

      await _locationRepo.updateUserLocation(position.latitude, position.longitude);
      print("Location updated on server");

      if (service is AndroidServiceInstance) {
        await service.setForegroundNotificationInfo(
          title: "Location Tracking",
          content: "Last update: ${DateTime.now().toIso8601String()}",
        );
      }
    } catch (e) {
      print("Location fetch failed in background: $e");
      // Handle specific errors if needed, e.g., location unavailable
    }
  });
}

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create:
              (context) =>
          AuthBloc(AuthRepository())
            ..add(CheckLoginStatusEvent()),
        ),
        BlocProvider(
          create: (context) => LocationBloc(), // Inject LocationBloc here
        ),
      ],
      child: MultiRepositoryProvider(
        providers: [
          // RepositoryProvider(create: (_) => UserLocationRepository()),
          RepositoryProvider(create: (_) => AuthRepository()),
          // RepositoryProvider(create: (_) => MatchUsersRepository()),
          // RepositoryProvider(create: (_) => UserService()),
          // RepositoryProvider(create: (_) => MessageService()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          // navigatorKey: navigatorKey,
          // locale: const Locale('ja', 'JP'),
          // supportedLocales: const [Locale('ja', 'JP'), Locale('en', 'US')],
          // localizationsDelegates: [
          //   // Removed const
          //   GlobalMaterialLocalizations.delegate,
          //   GlobalWidgetsLocalizations.delegate,
          //   GlobalCupertinoLocalizations.delegate,
          // ],
          title: 'Flutter Auth with BLoC',
          theme: ThemeData(primarySwatch: Colors.blue),
          initialRoute: '/auth',
          routes: {
            '/auth': (context) => AuthScreen(),
            '/home': (context) => ChatScreen(),
          },
          // onGenerateRoute: (settings) {
          //   if (settings.name == '/chat') {
          //     final args = settings.arguments as Map<String, dynamic>?;
          //     if (args != null) {
          //       return MaterialPageRoute(
          //         builder:
          //             (_) => ChatScreen(
          //           senderId: args['senderId'],
          //           receiverId: args['receiverId'],
          //           route: args['route'],
          //         ),
          //       );
          //     }
          //   }
          //   return null;
          // },
        ),
      ),
    ),
  );

}

