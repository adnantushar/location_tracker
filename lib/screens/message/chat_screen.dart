import 'package:flutter/material.dart';
import 'package:location_tracker/screens/settings_screen.dart';


class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Home'),
        backgroundColor: Colors.blueAccent,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blueAccent,
              ),
              child: Text(
                'Location Tracker',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Chat'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // Already on ChatScreen, do nothing or navigate to self
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
            // Add more list tiles for other navigation options if needed
          ],
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Welcome to the Chat Screen!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              'Use the sidebar to navigate to settings.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
//
// class ChatScreen extends StatelessWidget {
//   const ChatScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//           title:Text("Chat Screen")
//       ),
//       body: Center(
//           child:Text("Welcome to Chat")
//       ),
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// // import 'package:geolocator/geolocator.dart';
// import 'package:location_tracker/bloc/location/location_bloc.dart';
// import 'package:location_tracker/bloc/location/location_event.dart';
// import 'package:location_tracker/bloc/location/location_state.dart';
//
// class ChatScreen extends StatelessWidget {
//   const ChatScreen({super.key});

  // void _onToggleChanged(BuildContext context, bool value) async {
  //   if (value) {
  //     LocationPermission permission = await Geolocator.checkPermission();
  //     if (permission == LocationPermission.denied ||
  //         permission == LocationPermission.deniedForever) {
  //       permission = await Geolocator.requestPermission();
  //     }
  //
  //     if (permission != LocationPermission.always &&
  //         permission != LocationPermission.whileInUse) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text("Location permission is required")),
  //       );
  //       return;
  //     }
  //   }
  //
  //   context.read<LocationBloc>().add(ToggleLocation(value));
  // }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Chat")),
//       body: Column(
//         children: [
//           // Your chat UI here...
//
//           // Location Toggle UI
//           BlocBuilder<LocationBloc, LocationState>(
//             builder: (context, state) {
//               final isEnabled = state is LocationEnabled;
//               return SwitchListTile(
//                 title: const Text("Enable Background Location"),
//                 value: isEnabled,
//                 onChanged: (value) {
//                   context.read<LocationBloc>().add(ToggleLocation(value));
//                 },
//                 // value: isEnabled,
//                 // onChanged: (value) => _onToggleChanged(context, value),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }
