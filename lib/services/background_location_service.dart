import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location_tracker/data/repositories/user_location_repository.dart';

void startBackgroundService() async {
  final service = FlutterBackgroundService();
  if (await service.isRunning()) {
    print("Background service already running");
    return;
  }
  await service.startService();
}

void stopBackgroundService() {
  final service = FlutterBackgroundService();
  service.invoke("stop");
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      notificationChannelId: 'location_channel',
      initialNotificationTitle: 'Location Tracking Service',
      initialNotificationContent: 'Tracking your location in the background',
      foregroundServiceNotificationId: 888,
      // foregroundServiceTypes: AndroidForegroundType.location, // Specify location type
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

Future<bool> _checkPermissionForBackground() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    print("Location services are disabled");
    return false;
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.deniedForever) {
    print("Location permissions are permanently denied");
    return false;
  }

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
      print("Location permission not granted");
      return false;
    }
  }

  // Request background location permission for Android 10+
  if (permission != LocationPermission.always) {
    permission = await Geolocator.requestPermission();
    if (permission != LocationPermission.always) {
      print("Background location permission not granted");
      return false;
    }
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
  DartPluginRegistrant.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final UserLocationRepository _locationRepo = UserLocationRepository();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on("stop").listen((event) {
    service.stopSelf();
    print("Background service stopped");
  });

  Timer.periodic(const Duration(seconds: 30), (timer) async {
    if (service is AndroidServiceInstance && !await service.isForegroundService()) {
      service.setAsForegroundService();
    }

    print("Service running at ${DateTime.now()}");
    if (!await _checkPermissionForBackground()) {
      print("Background location permissions not granted");
      return;
    }

    try {
      LocationSettings locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update only if moved 10 meters
      );

      Position pos = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      print("Position: $pos");

      await _locationRepo.updateUserLocation(pos.latitude, pos.longitude);
      print("Location updated successfully");

      // Update notification content
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Location Tracking Service",
          content: "Last updated: ${DateTime.now().toIso8601String()}",
        );
      }
    } catch (e) {
      print("Error in background service: $e");
    }
  });
}