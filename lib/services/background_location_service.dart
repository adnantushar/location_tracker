import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location_tracker/data/repositories/user_location_repository.dart';

final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
bool isServiceRunning = false;

void startLocationService() async {
  final service = FlutterBackgroundService();
  if (await service.isRunning()) {
    print("Background service already running");
    return;
  }
  await service.startService();
  isServiceRunning = true;
}

void stopLocationService() {
  final service = FlutterBackgroundService();
  service.invoke("stop");
  isServiceRunning = false;
}

Future<void> _createNotificationChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'location_channel',
    'Location Tracking',
    description: 'This channel is used for background location tracking',
    importance: Importance.low,
    playSound: false,
  );

  await _localNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

Future<void> initializeService() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification plugin
  const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings = InitializationSettings(android: androidInit);
  await _localNotificationsPlugin.initialize(initSettings);

  await _createNotificationChannel();

  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'location_channel',
      initialNotificationTitle: 'Location Tracking',
      initialNotificationContent: 'Tracking in background',
      foregroundServiceNotificationId: 888,
      foregroundServiceTypes: [AndroidForegroundType.location],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  if (!await service.isRunning()) {
    await service.startService();
  }
  isServiceRunning = true;
}

Future<bool> _checkPermissionForBackground() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    print("Location services are disabled");
    return false;
  };

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.deniedForever || permission != LocationPermission.always) {
    return false;
  }

  return true;
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  // DartPluginRegistrant.ensureInitialized();

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final UserLocationRepository _locationRepo = UserLocationRepository();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();

    service.on("stop").listen((event) {
      service.stopSelf();
      print("Background service stopped");
    });
  }

  Timer.periodic(const Duration(seconds: 30), (timer) async {
    print("Background task running now");
    if (!await _checkPermissionForBackground()) {
      print("Background permission not granted");
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

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
      print("Location fetch failed: $e");
    }
  });
}
