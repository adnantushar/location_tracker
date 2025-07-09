part of 'location_bloc.dart';

abstract class LocationServiceState extends Equatable {
  const LocationServiceState();

  @override
  List<Object> get props => [];
}

class LocationServiceInitial extends LocationServiceState {}

class LocationServiceRunning extends LocationServiceState {
  final String lastUpdateTime;
  const LocationServiceRunning({this.lastUpdateTime = 'N/A'});

  @override
  List<Object> get props => [lastUpdateTime];
}

class LocationServiceStopped extends LocationServiceState {}

class LocationServicePermissionRequired extends LocationServiceState {
  final String message;
  final PermissionType type; // e.g., 'location_service_disabled', 'permission_denied', 'permission_denied_forever', 'permission_while_in_use'
  const LocationServicePermissionRequired(this.message, this.type);

  @override
  List<Object> get props => [message, type];
}

class LocationServiceError extends LocationServiceState {
  final String message;
  const LocationServiceError(this.message);

  @override
  List<Object> get props => [message];
}

enum PermissionType {
  locationServiceDisabled,
  permissionDenied,
  permissionDeniedForever,
  permissionWhileInUse,
  // Add other types as needed
}
