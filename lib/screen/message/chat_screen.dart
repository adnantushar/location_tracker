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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:geolocator/geolocator.dart';
import 'package:location_tracker/bloc/location/location_bloc.dart';
import 'package:location_tracker/bloc/location/location_event.dart';
import 'package:location_tracker/bloc/location/location_state.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat")),
      body: Column(
        children: [
          // Your chat UI here...

          // Location Toggle UI
          BlocBuilder<LocationBloc, LocationState>(
            builder: (context, state) {
              final isEnabled = state is LocationEnabled;
              return SwitchListTile(
                title: const Text("Enable Background Location"),
                value: isEnabled,
                onChanged: (value) {
                  context.read<LocationBloc>().add(ToggleLocation(value));
                },
                // value: isEnabled,
                // onChanged: (value) => _onToggleChanged(context, value),
              );
            },
          ),
        ],
      ),
    );
  }
}
