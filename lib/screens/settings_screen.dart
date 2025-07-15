import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location_tracker/bloc/location/location_bloc.dart';


class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _showPermissionDialog(BuildContext context, String title, String content, PermissionType type) async {
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            if (type == PermissionType.locationServiceDisabled)
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Geolocator.openLocationSettings();
                },
                child: const Text("Open Settings"),
              ),
            // For permissionDenied, deniedForever, and whileInUse, direct to app settings
            if (type == PermissionType.permissionDenied ||
                type == PermissionType.permissionDeniedForever ||
                type == PermissionType.permissionWhileInUse)
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Geolocator.openAppSettings();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: BlocConsumer<LocationServiceBloc, LocationServiceState>(
                  listener: (context, state) {
                    if (state is LocationServicePermissionRequired) {
                      String title;
                      String content;
                      switch (state.type) {
                        case PermissionType.locationServiceDisabled:
                          title = "Location Services Disabled";
                          content = "Please enable location services to allow the app to track your location.";
                          break;
                        case PermissionType.permissionDenied:
                          title = "Location Permission Required";
                          content = "Location permission was denied. Please grant it from app settings.";
                          break; // Updated content
                        case PermissionType.permissionDeniedForever:
                          title = "Location Permission Permanently Denied";
                          content = "Location permission was permanently denied. Please go to app settings and enable 'Always Allow' for background tracking.";
                          break;
                        case PermissionType.permissionWhileInUse:
                          title = "Background Location Needed";
                          content = "For continuous location tracking in the background, please change the location permission to 'Always Allow' in app settings.";
                          break;
                      }
                      _showPermissionDialog(context, title, content, state.type);
                    } else if (state is LocationServiceError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${state.message}')),
                      );
                    } else if (state is LocationServiceRunning) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Location tracking started!')),
                      );
                    } else if (state is LocationServiceStopped) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Location tracking stopped!')),
                      );
                    }
                  },
                  builder: (context, state) {
                    final bool isRunning = state is LocationServiceRunning;
                    String subtitleText;
                    if (state is LocationServiceRunning) {
                      subtitleText = 'Location service is currently active in the background. Last update: ${state.lastUpdateTime}';
                    } else if (state is LocationServiceStopped) {
                      subtitleText = 'Location service is currently stopped.';
                    } else if (state is LocationServiceInitial) {
                      subtitleText = 'Checking service status...';
                    } else if (state is LocationServicePermissionRequired) {
                      subtitleText = 'Action required: ${state.message}'; // This message is critical
                    } else if (state is LocationServiceError) {
                      subtitleText = 'An error occurred: ${state.message}';
                    } else {
                      subtitleText = 'Unknown service status.';
                    }

                    return SwitchListTile(
                      title: const Text(
                        'Enable Background Location Tracking',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        subtitleText,
                        style: TextStyle(color: isRunning ? Colors.green : Colors.red),
                      ),
                      value: isRunning,
                      onChanged: (bool newValue) async {
                        final bloc = BlocProvider.of<LocationServiceBloc>(context);
                        if (newValue) {
                          bloc.add(StartTrackingRequested());
                        } else {
                          bloc.add(StopTrackingRequested());
                        }
                      },
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.grey,
                      activeTrackColor: Colors.green.withOpacity(0.5),
                      inactiveTrackColor: Colors.grey.withOpacity(0.5),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Note: For continuous background tracking, ensure your app has "Always Allow" location permission in your device settings.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}