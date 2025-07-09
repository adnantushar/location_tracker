import 'dart:async';
import 'dart:ui';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart'; // For WidgetsFlutterBinding
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location_tracker/data/repositories/user_location_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'location_state.dart';
part 'location_event.dart'; // Include events here

// Global notification plugin instance
final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

class LocationServiceBloc extends Bloc<LocationServiceEvent, LocationServiceState> {
  final UserLocationRepository _locationRepo;
  final FlutterBackgroundService _backgroundService;

  LocationServiceBloc(this._locationRepo)
      : _backgroundService = FlutterBackgroundService(),
        super(LocationServiceInitial()) {
    on<CheckInitialServiceStatus>(_onCheckInitialServiceStatus);
    on<StartTrackingRequested>(_onStartTrackingRequested);
    on<StopTrackingRequested>(_onStopTrackingRequested);
    on<BackgroundServiceStarted>(_onBackgroundServiceStarted);
    on<BackgroundServiceStopped>(_onBackgroundServiceStopped);
    on<LocationUpdateReceived>(_onLocationUpdateReceived);
    on<LocationUpdateFailed>(_onLocationUpdateFailed);

    add(CheckInitialServiceStatus());
    _listenToBackgroundServiceEvents();
  }

  void _listenToBackgroundServiceEvents() {
    _backgroundService.on('service_started_bg').listen((event) {
      add(BackgroundServiceStarted(lastUpdate: event?['last_update']));
    });
    _backgroundService.on('service_stopped_bg').listen((event) {
      add(BackgroundServiceStopped());
    });
    _backgroundService.on('location_update_success_bg').listen((event) {
      add(LocationUpdateReceived(event?['last_update']));
    });
    _backgroundService.on('location_update_failed_bg').listen((event) {
      add(LocationUpdateFailed(event?['last_update'], event?['error']));
    });
  }

  Future<void> _onCheckInitialServiceStatus(
      CheckInitialServiceStatus event, Emitter<LocationServiceState> emit) async {
    if (await _backgroundService.isRunning()) {
      emit(const LocationServiceRunning(lastUpdateTime: 'Service already active'));
    } else {
      emit(LocationServiceStopped());
    }
  }

  Future<void> _onStartTrackingRequested(
      StartTrackingRequested event, Emitter<LocationServiceState> emit) async {
    emit(LocationServiceInitial());

    // 1. Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      emit(const LocationServicePermissionRequired(
          "Please enable location services.", PermissionType.locationServiceDisabled));
      return;
    }

    // 2. Check current location permission status
    LocationPermission permission = await Geolocator.checkPermission();

    // If permission is denied, request it from the user
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // Now, evaluate the permission status AFTER potentially requesting it
    if (permission == LocationPermission.denied) {
      // User denied the permission (again, or first time)
      emit(const LocationServicePermissionRequired(
          "Location permission required. Please grant it.", PermissionType.permissionDenied));
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      emit(const LocationServicePermissionRequired(
          "Location permission permanently denied. Please enable from app settings.", PermissionType.permissionDeniedForever));
      return;
    }

    // On Android, LocationPermission.granted often means "While in Use".
    // For background tracking, we need "Always Allow".
    // On iOS, you can also get "When in Use" and need to prompt for "Always".
    // We check for "always" explicitly here. If not "always", prompt user to go to settings.
    if (permission != LocationPermission.always) {
      emit(const LocationServicePermissionRequired(
          "For continuous background tracking, please grant 'Always Allow' permission.", PermissionType.permissionWhileInUse));
      return;
    }

    // If we reach here, all necessary permissions and services are active.
    // Attempt to start the background service.
    if (!await _backgroundService.isRunning()) {
      await _backgroundService.startService();
      // The actual state will be updated by BackgroundServiceStarted event coming from background isolate
      emit(const LocationServiceRunning(lastUpdateTime: 'Initiating service...'));
    } else {
      emit(const LocationServiceRunning(lastUpdateTime: 'Service already running.'));
    }
  }

  Future<void> _onStopTrackingRequested(
      StopTrackingRequested event, Emitter<LocationServiceState> emit) async {
    if (await _backgroundService.isRunning()) {
      _backgroundService.invoke("stop");
      emit(LocationServiceInitial()); // Transitioning to stopped
    } else {
      emit(LocationServiceStopped());
    }
  }

  void _onBackgroundServiceStarted(
      BackgroundServiceStarted event, Emitter<LocationServiceState> emit) {
    emit(LocationServiceRunning(lastUpdateTime: event.lastUpdate ?? 'Service running'));
  }

  void _onBackgroundServiceStopped(
      BackgroundServiceStopped event, Emitter<LocationServiceState> emit) {
    emit(LocationServiceStopped());
  }

  void _onLocationUpdateReceived(
      LocationUpdateReceived event, Emitter<LocationServiceState> emit) {
    emit(LocationServiceRunning(lastUpdateTime: event.lastUpdate));
  }

  void _onLocationUpdateFailed(
      LocationUpdateFailed event, Emitter<LocationServiceState> emit) {
    print("Location update failed in BLoC: ${event.error}");
    emit(LocationServiceRunning(lastUpdateTime: '${event.lastUpdate} (Failed)'));
  }

  // --- Background Service Configuration (static, called once in main) ---
  static Future<void> configureBackgroundService() async {
    WidgetsFlutterBinding.ensureInitialized();

    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidInit);
    await _localNotificationsPlugin.initialize(initSettings);

    await _createNotificationChannel();

    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onBackgroundServiceStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'location_channel',
        initialNotificationTitle: 'Location Tracking',
        initialNotificationContent: 'Tracking in background',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onBackgroundServiceStart,
        onBackground: onIosBackground,
      ),
    );
  }

  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'location_channel',
      'Location Tracking',
      description: 'This channel is used for background location tracking',
      importance: Importance.low,
      playSound: false,
      enableLights: false,
      enableVibration: false,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
}

// --- Background Isolate Entry Points ---
// These are global functions for flutter_background_service.
// They run in a separate isolate and communicate back to the main isolate via `service.invoke`.

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onBackgroundServiceStart(ServiceInstance service) async {
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
