import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'location_event.dart';
import 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  LocationBloc() : super(LocationInitial()) {
    on<ToggleLocation>((event, emit) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('location_enabled', event.enabled);
      print("Toggle button clicked");
      if (event.enabled) {
        emit(LocationEnabled());
      } else {
        emit(LocationDisabled());
      }
    });
  }
}
