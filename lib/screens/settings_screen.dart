import 'package:flutter/material.dart';
import 'package:location_tracker/main.dart'; // Import main.dart to access global functions and notifier

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blueAccent,
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
                child: ValueListenableBuilder<bool>(
                  valueListenable: isServiceRunningNotifier,
                  builder: (context, isRunning, child) {
                    return SwitchListTile(
                      title: const Text(
                        'Enable Background Location Tracking',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        isRunning
                            ? 'Location service is currently active in the background.'
                            : 'Location service is currently stopped.',
                        style: TextStyle(color: isRunning ? Colors.green : Colors.red),
                      ),
                      value: isRunning,
                      onChanged: (bool newValue) async {
                        if (newValue) {
                          // User wants to turn ON tracking
                          bool granted = await requestAndCheckLocationPermissions(context);
                          if (granted) {
                            startLocationService();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Location tracking started!')),
                            );
                          } else {
                            // If permissions not granted, the switch should revert
                            // The ValueNotifier will handle the UI update automatically
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not start tracking: Permissions not granted.')),
                            );
                          }
                        } else {
                          // User wants to turn OFF tracking
                          stopLocationService();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Location tracking stopped!')),
                          );
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